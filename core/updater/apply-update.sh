#!/usr/bin/env bash
# apply-update.sh - ダウンロード＋検証＋core/ 差し替え＋コミット
#
# 使用法:
#   core/updater/apply-update.sh --tag vX.Y.Z [--dry-run] [--skip-snapshot]
#
# このスクリプトは:
#   1. （任意）スナップショットコミットを作成
#   2. GitHub からリリース ZIP をダウンロード
#   3. checksums.txt で完全性検証
#   4. ZIP を展開
#   5. core/ を新版で差し替え
#   6. ルート雛形を 3-way 判定で更新
#   7. lock.json を再生成
#   8. 更新コミットを作成（--dry-run 時はスキップ）
#
# exit codes:
#   0  = 成功
#   1  = 一般エラー
#   20 = ネットワークエラー
#   21 = rate limit
#   22 = チェックサム不一致
#   23 = 依存ツール不足

set -uo pipefail

DRY_RUN=0
SKIP_SNAPSHOT=0
TAG=""
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --skip-snapshot) SKIP_SNAPSHOT=1 ;;
        --tag) shift_next=1 ;;
        *)
            if [[ "${shift_next:-0}" == "1" ]]; then
                TAG="$arg"
                shift_next=0
            elif [[ "$arg" == --tag=* ]]; then
                TAG="${arg#--tag=}"
            elif [[ "$arg" == --help || "$arg" == -h ]]; then
                sed -n '2,20p' "$0"
                exit 0
            fi
            ;;
    esac
done

if [[ -z "$TAG" ]]; then
    echo "usage: apply-update.sh --tag vX.Y.Z [--dry-run] [--skip-snapshot]" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=lib/hash.sh
. "$SCRIPT_DIR/lib/hash.sh"
# shellcheck source=lib/lock.sh
. "$SCRIPT_DIR/lib/lock.sh"
# shellcheck source=lib/github.sh
. "$SCRIPT_DIR/lib/github.sh"
# shellcheck source=lib/root-merge.sh
. "$SCRIPT_DIR/lib/root-merge.sh"

cd "$WORKSPACE_ROOT" || exit 1

# --- 依存ツール確認 ---
for cmd in curl git; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "apply-update: missing dependency: $cmd" >&2
        exit 23
    fi
done
# unzip または tar のいずれか必須（ZIP 展開に使用）
if ! command -v unzip >/dev/null 2>&1 && ! command -v tar >/dev/null 2>&1; then
    echo "apply-update: neither unzip nor tar available" >&2
    exit 23
fi
hash_detect_tool >/dev/null 2>&1 || {
    echo "apply-update: neither shasum nor sha256sum available" >&2
    exit 23
}

NEW_VERSION="${TAG#v}"
ZIP_URL_BASE="https://github.com/${GITHUB_REPO:-KumaBase/agent-base}/archive/refs/tags/${TAG}.zip"

# Git リポジトリかどうか
HAS_GIT=0
if git rev-parse --git-dir >/dev/null 2>&1; then
    HAS_GIT=1
fi

echo "[1/8] Target: $TAG (v$NEW_VERSION)" >&2

# --- 2. スナップショットコミット（Git 有効・dry-run 無し・skip-snapshot 無し） ---
if [[ $HAS_GIT -eq 1 && $DRY_RUN -eq 0 && $SKIP_SNAPSHOT -eq 0 ]]; then
    if ! git diff --quiet HEAD -- core/ 2>/dev/null || \
       ! git diff --cached --quiet HEAD -- core/ 2>/dev/null; then
        echo "[2/8] Creating snapshot commit before update..." >&2
        git add -A -- core/ 2>/dev/null
        if ! git commit -m "chore: snapshot before agent-base update" >/dev/null 2>&1; then
            echo "apply-update: failed to create snapshot commit" >&2
            exit 1
        fi
        echo "      Snapshot created. To rollback: git reset --hard HEAD~1" >&2
    else
        echo "[2/8] No uncommitted changes in core/. Skip snapshot." >&2
    fi
else
    echo "[2/8] Snapshot step skipped (dry-run=$DRY_RUN, git=$HAS_GIT, skip=$SKIP_SNAPSHOT)" >&2
fi

# --- 3. ZIP ダウンロード ---
TMPDIR_WORK="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_WORK"' EXIT

ZIP_FILE="$TMPDIR_WORK/agent-base.zip"
echo "[3/8] Downloading $ZIP_URL_BASE ..." >&2
if ! github_download "$ZIP_URL_BASE" "$ZIP_FILE"; then
    echo "apply-update: download failed" >&2
    exit 20
fi
if [[ ! -s "$ZIP_FILE" ]]; then
    echo "apply-update: downloaded file is empty" >&2
    exit 20
fi

# --- 4. checksums.txt 検証（可能なら） ---
echo "[4/8] Verifying integrity..." >&2

# リリース情報を取得して checksums.txt を探す
RELEASE_JSON="$(github_get_release_by_tag "$TAG" 2>/dev/null)" || RELEASE_JSON=""
ZIP_SUM="$(hash_compute_sha256 "$ZIP_FILE" 2>/dev/null)" || ZIP_SUM=""

# checksums.txt を取得してみる（無くても続行可能。ただし警告）
CHECKSUMS_OK=0
if [[ -n "$RELEASE_JSON" ]]; then
    CHECKSUMS="$(printf '%s' "$RELEASE_JSON" | github_get_checksums 2>/dev/null)" || CHECKSUMS=""
    rc=$?
    if [[ $rc -eq 0 && -n "$CHECKSUMS" ]]; then
        # checksums.txt の各行: "<sha256>  <filename>"
        EXPECTED_ZIP_SUM="$(echo "$CHECKSUMS" | awk '/[\/ ]agent-base.*\.zip$|Source.*zip|^([a-f0-9]+[[:space:]]+star\/)?[a-f0-9]+[[:space:]]+\*?$/ {print $1; exit}' 2>/dev/null)"
        # より確実: ZIP 全体のエントリを探す
        if [[ -z "$EXPECTED_ZIP_SUM" ]]; then
            # 最初の行の hash を ZIP 全体とみなす（v0.0.2 以降の形式）
            EXPECTED_ZIP_SUM="$(echo "$CHECKSUMS" | grep -E '^[a-f0-9]{64}' | head -1 | awk '{print $1}')"
        fi
        if [[ -n "$EXPECTED_ZIP_SUM" ]]; then
            actual_sum="${ZIP_SUM#sha256:}"
            if [[ "$actual_sum" == "$EXPECTED_ZIP_SUM" ]]; then
                echo "      ZIP checksum OK ($actual_sum)" >&2
                CHECKSUMS_OK=1
            else
                echo "apply-update: ZIP checksum mismatch" >&2
                echo "  expected: $EXPECTED_ZIP_SUM" >&2
                echo "  actual:   $actual_sum" >&2
                exit 22
            fi
        else
            echo "      [warn] checksums.txt found but ZIP entry not located. Continuing." >&2
        fi
    elif [[ $rc -eq 10 ]]; then
        echo "      [warn] checksums.txt not attached to release $TAG." >&2
        echo "             Older releases (v0.0.1) may not have checksums." >&2
        echo "             Continuing without verification." >&2
    else
        echo "      [warn] Failed to fetch checksums.txt (network?). Continuing." >&2
    fi
else
    echo "      [warn] Release metadata unavailable. Skipping checksums verification." >&2
fi

# --- 5. 展開 ---
echo "[5/8] Extracting archive..." >&2
EXTRACT_DIR="$TMPDIR_WORK/extracted"
mkdir -p "$EXTRACT_DIR"
# unzip を優先、なければ tar（macOS bsdtar / GNU tar / Windows 10 tar いずれも ZIP 対応）
extract_ok=0
if command -v unzip >/dev/null 2>&1; then
    if unzip -q "$ZIP_FILE" -d "$EXTRACT_DIR" 2>/dev/null; then
        extract_ok=1
    fi
fi
if [[ $extract_ok -eq 0 ]] && command -v tar >/dev/null 2>&1; then
    # tar は -C で展開先指定
    if tar -xf "$ZIP_FILE" -C "$EXTRACT_DIR" 2>/dev/null; then
        extract_ok=1
    fi
fi
if [[ $extract_ok -eq 0 ]]; then
    echo "apply-update: archive extraction failed (tried unzip and tar)" >&2
    exit 1
fi

# 展開されたトップディレクトリ（agent-base-XX.Y.Z のような名前）を特定
EXTRACTED_ROOT="$(find "$EXTRACT_DIR" -maxdepth 1 -mindepth 1 -type d | head -1)"
if [[ -z "$EXTRACTED_ROOT" || ! -d "$EXTRACTED_ROOT/core" ]]; then
    echo "apply-update: extracted archive does not contain core/" >&2
    echo "  extracted_root: $EXTRACTED_ROOT" >&2
    ls -la "$EXTRACT_DIR" >&2
    exit 1
fi

echo "      Extracted to: $EXTRACTED_ROOT" >&2

# --- 6. core/ 差し替え ---
echo "[6/8] Replacing core/ ..." >&2

if [[ $DRY_RUN -eq 1 ]]; then
    echo "      [dry-run] Would replace core/ with new version" >&2
    # 差分を表示
    OLD_CORE_HASH_FILE="$TMPDIR_WORK/old_core.txt"
    NEW_CORE_HASH_FILE="$TMPDIR_WORK/new_core.txt"
    hash_compute_dir "$WORKSPACE_ROOT/core" >"$OLD_CORE_HASH_FILE" 2>/dev/null
    hash_compute_dir "$EXTRACTED_ROOT/core" >"$NEW_CORE_HASH_FILE" 2>/dev/null
    echo "      Diff (old → new):" >&2
    diff "$OLD_CORE_HASH_FILE" "$NEW_CORE_HASH_FILE" >&2 || true
else
    # core/ を退避してから差し替え
    BACKUP_DIR="$TMPDIR_WORK/core_backup"
    if [[ -d "$WORKSPACE_ROOT/core" ]]; then
        cp -a "$WORKSPACE_ROOT/core" "$BACKUP_DIR"
    fi

    # core/.agent-base-lock.json は保持対象（ユーザーの installed_at 等）
    OLD_LOCK="$BACKUP_DIR/.agent-base-lock.json"

    rm -rf "$WORKSPACE_ROOT/core"
    cp -a "$EXTRACTED_ROOT/core" "$WORKSPACE_ROOT/core"

    # lock が存在した場合は復元（hash 再計算は後で行う）
    if [[ -f "$OLD_LOCK" ]]; then
        cp -a "$OLD_LOCK" "$WORKSPACE_ROOT/core/.agent-base-lock.json"
    fi
    echo "      core/ replaced" >&2
fi

# --- 7. ルート雛形の 3-way マージ ---
echo "[7/8] Checking root templates..." >&2

# 現 lock の root_template_hashes を一時ファイルへ
ROOT_HASHES_FILE="$TMPDIR_WORK/root_hashes.txt"
lock_load_root_to_file "$ROOT_HASHES_FILE"

CONFLICTS=""
while IFS=$'\t' read -r path expected; do
    [[ -z "$path" ]] && continue
    safety="$(root_merge_is_safe_overwrite "$path" "$expected")"
    case "$safety" in
        safe)
            if [[ $DRY_RUN -eq 1 ]]; then
                echo "      [dry-run] Would overwrite (unchanged): $path" >&2
            else
                if [[ -f "$EXTRACTED_ROOT/$path" ]]; then
                    cp -a "$EXTRACTED_ROOT/$path" "$WORKSPACE_ROOT/$path"
                    echo "      Overwritten (unchanged): $path" >&2
                fi
            fi
            ;;
        needs-merge)
            echo "      [needs-merge] $path (user modified)" >&2
            CONFLICTS="${CONFLICTS}${path}|"
            if [[ $DRY_RUN -eq 0 && -f "$EXTRACTED_ROOT/$path" ]]; then
                cp -a "$EXTRACTED_ROOT/$path" "$WORKSPACE_ROOT/${path}.new"
                echo "        New version saved as: ${path}.new" >&2
            fi
            ;;
        missing)
            ;;
    esac
done <"$ROOT_HASHES_FILE"

# --- 8. lock 再生成 + コミット ---
echo "[8/8] Regenerating lock and committing..." >&2

if [[ $DRY_RUN -eq 0 ]]; then
    NEW_SOURCE="https://github.com/${GITHUB_REPO:-KumaBase/agent-base}/archive/refs/tags/${TAG}.zip"
    if ! lock_regenerate "$NEW_VERSION" "$NEW_SOURCE"; then
        echo "apply-update: lock regeneration failed" >&2
        exit 1
    fi
    echo "      lock.json regenerated" >&2

    # Git コミット
    if [[ $HAS_GIT -eq 1 ]]; then
        git add -A -- core/ 2>/dev/null
        # ルート雛形の上書き分もステージ
        while IFS=$'\t' read -r path _; do
            [[ -n "$path" && -f "$WORKSPACE_ROOT/$path" ]] && git add -- "$path" 2>/dev/null || true
        done <"$ROOT_HASHES_FILE"
        if ! git commit -m "chore: update agent-base to $TAG" >/dev/null 2>&1; then
            echo "      [warn] commit failed or nothing to commit" >&2
        else
            echo "      Committed: chore: update agent-base to $TAG" >&2
        fi
    fi
else
    echo "      [dry-run] Would regenerate lock.json and commit" >&2
fi

# --- レポート ---
echo "" >&2
echo "=== Update Report ===" >&2
echo "  Previous: (see lock history)" >&2
echo "  New:      v$NEW_VERSION ($TAG)" >&2
echo "  Checksum verified: $([[ $CHECKSUMS_OK -eq 1 ]] && echo yes || echo "skipped (no checksums.txt)")" >&2
if [[ -n "$CONFLICTS" ]]; then
    echo "  Root files needing manual merge:" >&2
    IFS='|' read -ra paths <<<"$CONFLICTS"
    for p in "${paths[@]}"; do
        [[ -n "$p" ]] && echo "    - $p (new version at ${p}.new)" >&2
    done
    echo "" >&2
    echo "  Action required: review .new files and merge into your customized versions." >&2
fi

# JSON サマリを stdout（jq 不要、printf + json_escape_string で構築）
{
    printf '{'
    printf '"version":"%s",' "$(json_escape_string "$NEW_VERSION")"
    printf '"tag":"%s",' "$(json_escape_string "$TAG")"
    if [[ $CHECKSUMS_OK -eq 1 ]]; then
        printf '"checksum_verified":true,'
    else
        printf '"checksum_verified":false,'
    fi
    if [[ $DRY_RUN -eq 1 ]]; then
        printf '"dry_run":true,'
    else
        printf '"dry_run":false,'
    fi
    # conflicts は | 区切り → JSON 配列
    printf '"conflicts":['
    _first=1
    IFS='|' read -ra _paths <<<"$CONFLICTS"
    for _p in "${_paths[@]}"; do
        [[ -z "$_p" ]] && continue
        if [[ $_first -eq 1 ]]; then _first=0; else printf ','; fi
        printf '"%s"' "$(json_escape_string "$_p")"
    done
    printf ']}'
}

exit 0
