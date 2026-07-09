#!/usr/bin/env bash
# root-merge.sh - ルート雛形の 3-way マージ判定
# lock の root_template_hashes（配布時）と現ファイルの hash を比較し、
# 利用者が改変したかどうかを判定する。
#
# bash 3.2 互換（連想配列不使用）。lock_get_root_template_hashes の出力を
# 直接処理する。

# root_merge_check <path> <expected_hash>
# 現ファイルの hash と expected（配布時）を比較。
#   戻り stdout: "unchanged" | "modified" | "missing"
root_merge_check() {
    local path="$1"
    local expected="$2"
    local script_dir workspace_root
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    workspace_root="$(cd "$script_dir/../../.." && pwd)"
    local fp="$workspace_root/$path"
    if [[ ! -f "$fp" ]]; then
        echo "missing"
        return 0
    fi
    local actual
    actual="$(hash_compute_sha256 "$fp" 2>/dev/null)" || actual=""
    if [[ "$actual" == "$expected" ]]; then
        echo "unchanged"
    else
        echo "modified"
    fi
}

# root_merge_iterate <hashes_file> <callback> [extra_arg...]
# hashes_file（"path\tsha256:hex" 形式）を1行ずつ読み、callback を呼ぶ。
# callback は引数として path, expected_hash, [extra_arg...] を受け取る。
# callback 内で変更したリストをファイルへ書き込むなどして状態を保持する。
root_merge_iterate() {
    local hashes_file="$1"
    local callback="$2"
    shift 2
    [[ -f "$hashes_file" ]] || return 0
    local path expected
    while IFS=$'\t' read -r path expected; do
        [[ -n "$path" ]] || continue
        "$callback" "$path" "$expected" "$@" || true
    done <"$hashes_file"
}

# root_merge_is_safe_overwrite <path> <old_expected_hash>
# 配布時 hash と現ファイル hash が一致（＝利用者未改変）なら上書き安全。
# stdout: "safe" | "needs-merge" | "missing"
root_merge_is_safe_overwrite() {
    local path="$1"
    local old_expected="$2"
    local status
    status="$(root_merge_check "$path" "$old_expected")"
    case "$status" in
        unchanged) echo "safe" ;;
        modified)  echo "needs-merge" ;;
        missing)   echo "missing" ;;
        *)         echo "needs-merge" ;;
    esac
}

# root_merge_list_changed <hashes_file>
# hashes_file に基づき「利用者が改変した」と判定されたファイルを stdout へ。
#   "<path>\t<status>" 形式（status は user-modified または missing）
root_merge_list_changed() {
    local hashes_file="$1"
    [[ -f "$hashes_file" ]] || return 0
    local path expected status
    while IFS=$'\t' read -r path expected; do
        [[ -n "$path" ]] || continue
        status="$(root_merge_check "$path" "$expected")"
        case "$status" in
            modified) printf '%s\t%s\n' "$path" "user-modified" ;;
            missing)  printf '%s\t%s\n' "$path" "missing" ;;
        esac
    done <"$hashes_file"
}
