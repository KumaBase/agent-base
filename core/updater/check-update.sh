#!/usr/bin/env bash
# check-update.sh - 最新版の有無を確認
#
# 使用法:
#   core/updater/check-update.sh [--force]
#
# exit codes:
#   0  = 既に最新
#   10 = 新版あり（stdout に JSON）
#   20 = ネットワークエラー
#   21 = GitHub API rate limit
#   22 = セットアップ未完了（lock の version が null）
#
# 新版ありの場合、stdout に以下の JSON を出力:
#   {"current":"0.0.1","latest":"0.0.2","tag":"v0.0.2","zip_url":"...","release_url":"...","changelog":"..."}

set -uo pipefail

FORCE=0
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=1 ;;
        --help|-h)
            sed -n '2,12p' "$0"
            exit 0
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# lib 読み込み
# shellcheck source=lib/hash.sh
. "$SCRIPT_DIR/lib/hash.sh"
# shellcheck source=lib/lock.sh
. "$SCRIPT_DIR/lib/lock.sh"
# shellcheck source=lib/github.sh
. "$SCRIPT_DIR/lib/github.sh"
# shellcheck source=lib/policy.sh
. "$SCRIPT_DIR/lib/policy.sh"

cd "$WORKSPACE_ROOT" || exit 20

# --- セットアップ済みか確認 ---
CURRENT_VERSION="$(lock_get_version)"
if [[ -z "$CURRENT_VERSION" || "$CURRENT_VERSION" == "null" ]]; then
    echo '{"error":"setup_incomplete","message":"lock version is null. Run setup first."}' >&2
    exit 22
fi

# --- 24h レート制限 ---
LAST_CHECK="$(lock_get_field "last_update_check_at")"
now_epoch="$(date -u +%s)"
if [[ $FORCE -eq 0 && -n "$LAST_CHECK" && "$LAST_CHECK" != "null" ]]; then
    # ISO8601 → epoch（macOS date と GNU date 両対応の簡易パース）
    last_clean="$(echo "$LAST_CHECK" | sed 's/\.[0-9]*Z$/Z/' | tr -d ' ')"
    last_epoch=""
    if command -v gdate >/dev/null 2>&1; then
        last_epoch="$(gdate -d "$last_clean" +%s 2>/dev/null || true)"
    fi
    if [[ -z "$last_epoch" ]]; then
        # macOS date
        last_epoch="$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$last_clean" +%s 2>/dev/null || true)"
    fi
    if [[ -z "$last_epoch" ]]; then
        # GNU date
        last_epoch="$(date -u -d "$last_clean" +%s 2>/dev/null || true)"
    fi
    if [[ -n "$last_epoch" ]]; then
        elapsed=$(( now_epoch - last_epoch ))
        if (( elapsed < 86400 )); then
            # 24h 未満。スキップ。
            exit 0
        fi
    fi
fi

# --- GitHub から最新リリース取得 ---
RELEASE_JSON="$(github_get_latest_release)"
rc=$?
if [[ $rc -ne 0 ]]; then
    # 通信エラー・rate limit 時は時刻を更新せず、24h以内の再チェックを阻害しない
    exit $rc
fi

if [[ -z "$RELEASE_JSON" ]]; then
    exit 20
fi

LATEST_TAG="$(printf '%s' "$RELEASE_JSON" | github_extract_tag)"
if [[ -z "$LATEST_TAG" ]]; then
    # パース失敗時は時刻を更新しない（24h スロットルを進めず再チェック可能に）
    echo '{"error":"parse_failed","message":"could not extract tag_name"}' >&2
    exit 20
fi

# 取得・パース成功後に last_update_check_at を更新（24h レート制限用）
lock_set_field "last_update_check_at" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" 2>/dev/null || true

# タグからバージョン番号を抽出（v0.0.2 → 0.0.2）
LATEST_VERSION="${LATEST_TAG#v}"

# --- semver 比較 ---
is_newer=0
if [[ "$LATEST_VERSION" != "$CURRENT_VERSION" ]]; then
    IFS=. read -r cur_major cur_minor cur_patch <<<"$CURRENT_VERSION"
    IFS=. read -r new_major new_minor new_patch <<<"$LATEST_VERSION"
    cur_major="${cur_major:-0}"; cur_minor="${cur_minor:-0}"; cur_patch="${cur_patch:-0}"
    new_major="${new_major:-0}"; new_minor="${new_minor:-0}"; new_patch="${new_patch:-0}"
    # 数字以外のサフィックスを除去（v0.1.0-rc1 等で算術エラーにならないように。
    # プレリリース序列は扱わない: 0.0.2-beta は 0.0.2 と同値として比較）
    cur_major="${cur_major%%[!0-9]*}"; cur_minor="${cur_minor%%[!0-9]*}"; cur_patch="${cur_patch%%[!0-9]*}"
    new_major="${new_major%%[!0-9]*}"; new_minor="${new_minor%%[!0-9]*}"; new_patch="${new_patch%%[!0-9]*}"
    # ゼロ詰めして数値比較
    cur_major=$((10#${cur_major:-0})); cur_minor=$((10#${cur_minor:-0})); cur_patch=$((10#${cur_patch:-0}))
    new_major=$((10#${new_major:-0})); new_minor=$((10#${new_minor:-0})); new_patch=$((10#${new_patch:-0}))
    if (( new_major > cur_major )) \
        || (( new_major == cur_major && new_minor > cur_minor )) \
        || (( new_major == cur_major && new_minor == cur_minor && new_patch > cur_patch )); then
        is_newer=1
    fi
fi

if [[ $is_newer -eq 0 ]]; then
    # 既に最新
    exit 0
fi

# --- 新版あり。JSON を構築して出力 ---
# zip_url は apply-update.sh の実ダウンロード対象と揃える:
# release asset（checksums.txt の検証対象）を優先し、無ければ zipball へ
# フォールバック。zipball は checksums.txt でカバーされない点に注意。
ZIP_URL="$(printf '%s' "$RELEASE_JSON" | github_find_asset_url "agent-base-${LATEST_VERSION}.zip")"
if [[ -z "$ZIP_URL" ]]; then
    ZIP_URL="$(printf '%s' "$RELEASE_JSON" | github_extract_zip_url)"
fi

# release JSON を temp file に保存して html_url/name/body を抽出
REL_TMP="$(mktemp)"
printf '%s' "$RELEASE_JSON" >"$REL_TMP"
RELEASE_URL="$(json_get_scalar "$REL_TMP" "html_url")"
RELEASE_NAME="$(json_get_scalar "$REL_TMP" "name")"
RELEASE_BODY="$(json_get_scalar "$REL_TMP" "body")"
rm -f "$REL_TMP"

# CHANGELOG から範囲抽出（ローカル）
CHANGELOG_SECTION="$(github_get_changelog_section "$CURRENT_VERSION" "$LATEST_VERSION")"

# JSON を構築して出力（jq 不要、printf + json_escape_string）
{
    printf '{'
    printf '"current":"%s",' "$(json_escape_string "$CURRENT_VERSION")"
    printf '"latest":"%s",' "$(json_escape_string "$LATEST_VERSION")"
    printf '"tag":"%s",' "$(json_escape_string "$LATEST_TAG")"
    printf '"zip_url":"%s",' "$(json_escape_string "$ZIP_URL")"
    printf '"release_url":"%s",' "$(json_escape_string "$RELEASE_URL")"
    printf '"release_name":"%s",' "$(json_escape_string "$RELEASE_NAME")"
    printf '"changelog":"%s",' "$(json_escape_string "$CHANGELOG_SECTION")"
    printf '"body":"%s"' "$(json_escape_string "$RELEASE_BODY")"
    printf '}'
}

exit 10
