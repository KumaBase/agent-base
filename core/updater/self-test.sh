#!/usr/bin/env bash
# self-test.sh - lock と現状の hash 整合性を検証
#
# 使用法:
#   core/updater/self-test.sh [--json]
#
# exit codes:
#   0 = 全一致
#   1 = 不一致あり（stdout/stderr に詳細）
#   2 = lock 未生成
#
# bash 3.2 互換（連想配列不使用）

set -uo pipefail

JSON_OUT=0
for arg in "$@"; do
    case "$arg" in
        --json) JSON_OUT=1 ;;
        --help|-h)
            sed -n '2,11p' "$0"
            exit 0
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=lib/hash.sh
. "$SCRIPT_DIR/lib/hash.sh"
# shellcheck source=lib/lock.sh
. "$SCRIPT_DIR/lib/lock.sh"

cd "$WORKSPACE_ROOT" || exit 1

# lock 未生成チェック
if ! lock_exists || [[ -z "$(lock_get_version)" || "$(lock_get_version)" == "null" ]]; then
    if [[ $JSON_OUT -eq 1 ]]; then
        printf '{"status":"setup_incomplete","message":"lock version is null"}'
    else
        echo "self-test: setup incomplete (lock version is null)" >&2
    fi
    exit 2
fi

# 一時ファイルに hash リストを取得
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

MANAGED_FILE="$TMP/managed.txt"
ROOT_FILE="$TMP/root.txt"
lock_load_managed_to_file "$MANAGED_FILE"
lock_load_root_to_file "$ROOT_FILE"

# managed_file_hashes を検証
MISMATCH_FILE="$TMP/mismatch.txt"
MISSING_FILE="$TMP/missing.txt"
EXTRA_FILE="$TMP/extra.txt"
ROOT_MISMATCH_FILE="$TMP/root_mismatch.txt"
: >"$MISMATCH_FILE"; : >"$MISSING_FILE"; : >"$EXTRA_FILE"; : >"$ROOT_MISMATCH_FILE"

# 1. lock にある各 managed path を検証
while IFS=$'\t' read -r path expected; do
    [[ -z "$path" ]] && continue
    fp="$WORKSPACE_ROOT/core/$path"
    if [[ ! -f "$fp" ]]; then
        echo "$path" >>"$MISSING_FILE"
        continue
    fi
    actual="$(hash_compute_sha256 "$fp" 2>/dev/null)" || actual=""
    if [[ "$actual" != "$expected" ]]; then
        echo "$path" >>"$MISMATCH_FILE"
    fi
done <"$MANAGED_FILE"

# 2. core/ 配下で lock に無いファイルを検出（extra）
while IFS= read -r -d '' f; do
    rel="${f#"$WORKSPACE_ROOT/core/"}"
    [[ "$rel" == ".agent-base-lock.json" ]] && continue
    # MANAGED_FILE に rel があるか
    if ! grep -q "^${rel}	" "$MANAGED_FILE" 2>/dev/null; then
        echo "$rel" >>"$EXTRA_FILE"
    fi
done < <(find "$WORKSPACE_ROOT/core" -type f -not -name '.DS_Store' -print0 2>/dev/null)

# 3. root_template_hashes をチェック（警告レベル）
while IFS=$'\t' read -r path expected; do
    [[ -z "$path" ]] && continue
    fp="$WORKSPACE_ROOT/$path"
    if [[ -f "$fp" ]]; then
        actual="$(hash_compute_sha256 "$fp" 2>/dev/null)" || actual=""
        if [[ "$actual" != "$expected" ]]; then
            echo "$path" >>"$ROOT_MISMATCH_FILE"
        fi
    fi
done <"$ROOT_FILE"

# 集計
mismatch_count=$(wc -l <"$MISMATCH_FILE" | tr -d ' ')
missing_count=$(wc -l <"$MISSING_FILE" | tr -d ' ')
extra_count=$(wc -l <"$EXTRA_FILE" | tr -d ' ')
root_mismatch_count=$(wc -l <"$ROOT_MISMATCH_FILE" | tr -d ' ')
total_problems=$(( mismatch_count + missing_count + extra_count ))

# 結果出力
if [[ $JSON_OUT -eq 1 ]]; then
    mm_arr="$(json_array_from_file "$MISMATCH_FILE")"
    ms_arr="$(json_array_from_file "$MISSING_FILE")"
    ex_arr="$(json_array_from_file "$EXTRA_FILE")"
    rm_arr="$(json_array_from_file "$ROOT_MISMATCH_FILE")"
    if [[ $total_problems -eq 0 ]]; then
        printf '{"status":"healthy","managed":{"mismatch":[],"missing":[],"extra":[]},"root_modified":%s}' "$rm_arr"
        exit 0
    fi
    printf '{"status":"issues","managed":{"mismatch":%s,"missing":%s,"extra":%s},"root_modified":%s}' \
        "$mm_arr" "$ms_arr" "$ex_arr" "$rm_arr"
    exit 1
fi

if [[ $total_problems -eq 0 ]]; then
    echo "self-test: core/ is healthy. All hashes match lock." >&2
    if [[ $root_mismatch_count -gt 0 ]]; then
        echo "" >&2
        echo "Note: root templates with user modifications:" >&2
        while IFS= read -r p; do
            [[ -n "$p" ]] && echo "  - $p" >&2
        done <"$ROOT_MISMATCH_FILE"
        echo "(These are informational. Run /core-update to merge.)" >&2
    fi
    exit 0
fi

echo "self-test: integrity issues detected" >&2
echo "" >&2
if [[ $mismatch_count -gt 0 ]]; then
    echo "Modified (hash mismatch):" >&2
    while IFS= read -r p; do
        [[ -n "$p" ]] && echo "  - core/$p" >&2
    done <"$MISMATCH_FILE"
fi
if [[ $missing_count -gt 0 ]]; then
    echo "Missing (in lock but not on disk):" >&2
    while IFS= read -r p; do
        [[ -n "$p" ]] && echo "  - core/$p" >&2
    done <"$MISSING_FILE"
fi
if [[ $extra_count -gt 0 ]]; then
    echo "Extra (on disk but not in lock):" >&2
    while IFS= read -r p; do
        [[ -n "$p" ]] && echo "  - core/$p" >&2
    done <"$EXTRA_FILE"
fi
echo "" >&2
echo "Recommended actions:" >&2
echo "  - Restore: re-run setup or /core-update" >&2
echo "  - Move customizations to rules/" >&2
echo "  - Allow temporarily (next self-test will warn again)" >&2

exit 1
