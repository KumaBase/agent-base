#!/usr/bin/env bash
# hash.sh - SHA256 計算・検証ユーティリティ
# 配布管理下。編集は AgentBase 公式アップデートのみ。
#
# 依存: shasum (macOS/BSD) または sha256sum (Linux)

# hash_detect_tool: SHA256 計算コマンドを検出
# stdout: コマンド名。未検出時は空で exit 1
hash_detect_tool() {
    if command -v shasum >/dev/null 2>&1; then
        echo "shasum"
        return 0
    fi
    if command -v sha256sum >/dev/null 2>&1; then
        echo "sha256sum"
        return 0
    fi
    return 1
}

# hash_compute_sha256 <path>
# stdout: "sha256:<hex>" 形式。ファイル不存在は exit 1
hash_compute_sha256() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        echo "hash_compute_sha256: file not found: $path" >&2
        return 1
    fi
    local tool sum
    tool="$(hash_detect_tool)" || {
        echo "hash_compute_sha256: neither shasum nor sha256sum available" >&2
        return 1
    }
    case "$tool" in
        shasum)
            sum="$(shasum -a 256 -- "$path" 2>/dev/null | awk '{print $1}')" || return 1
            ;;
        sha256sum)
            sum="$(sha256sum -- "$path" 2>/dev/null | awk '{print $1}')" || return 1
            ;;
        *)
            echo "hash_compute_sha256: unknown tool: $tool" >&2
            return 1
            ;;
    esac
    if [[ -z "$sum" || ${#sum} -ne 64 ]]; then
        echo "hash_compute_sha256: invalid digest for $path" >&2
        return 1
    fi
    echo "sha256:${sum}"
}

# hash_compute_sha256_stdin <input on stdin>
# stdout: "sha256:<hex>"
hash_compute_sha256_stdin() {
    local tool sum
    tool="$(hash_detect_tool)" || return 1
    case "$tool" in
        shasum)    sum="$(shasum -a 256 | awk '{print $1}')" ;;
        sha256sum) sum="$(sha256sum | awk '{print $1}')" ;;
        *) return 1 ;;
    esac
    [[ -n "$sum" && ${#sum} -eq 64 ]] || return 1
    echo "sha256:${sum}"
}

# hash_verify_dir <dir> <expected_hashes_file>
# 指定ディレクトリ配下の全ファイルを走査し、expected_hashes_file（"path\tsha256:hex" 形式）と照合。
# 戻り値:
#   stdout: 不一致ファイルパスを1行ずつ ("extra: path", "modified: path", "missing: path")
#   exit 0: 全一致
#   exit 1: 不一致あり
# expected_hashes_file の形式: 各行 "relative_path\tsha256:hex"
hash_verify_dir() {
    local dir="$1"
    local expected_file="$2"
    local mismatch_count=0
    local missing_count=0

    [[ -d "$dir" ]] || return 0
    [[ -f "$expected_file" ]] || return 0

    # expected を一時的なパス→hash マップ（正規表現マッチ）として使う
    # core/ 配下の各ファイルを走査
    local f rel actual expected_hash
    while IFS= read -r -d '' f; do
        rel="${f#"$dir"/}"
        [[ "$rel" == ".agent-base-lock.json" ]] && continue
        actual="$(hash_compute_sha256 "$f" 2>/dev/null)" || continue
        # expected_file から該当パスの hash を検索
        expected_hash="$(awk -F'\t' -v p="$rel" '$1 == p {print $2; exit}' "$expected_file" 2>/dev/null)"
        if [[ -z "$expected_hash" ]]; then
            echo "extra: $rel"
            mismatch_count=$((mismatch_count + 1))
        elif [[ "$actual" != "$expected_hash" ]]; then
            echo "modified: $rel"
            mismatch_count=$((mismatch_count + 1))
        fi
    done < <(find "$dir" -type f -not -name '.DS_Store' -print0 2>/dev/null)

    # expected_file にあるが実ファイル無いもの
    local k
    while IFS=$'\t' read -r k _; do
        [[ -n "$k" ]] || continue
        if [[ ! -f "$dir/$k" ]]; then
            echo "missing: $k"
            missing_count=$((missing_count + 1))
        fi
    done <"$expected_file"

    [[ $mismatch_count -eq 0 && $missing_count -eq 0 ]]
}

# hash_compute_dir <dir>
# 指定ディレクトリ配下の全ファイルの hash を計算。
# stdout: "<relative_path>\t<sha256:hex>" 形式
hash_compute_dir() {
    local dir="$1"
    [[ -d "$dir" ]] || return 0
    local f rel h
    while IFS= read -r -d '' f; do
        rel="${f#"$dir"/}"
        [[ "$rel" == ".agent-base-lock.json" ]] && continue
        h="$(hash_compute_sha256 "$f" 2>/dev/null)" || continue
        printf '%s\t%s\n' "$rel" "$h"
    done < <(find "$dir" -type f -not -name '.DS_Store' -print0 2>/dev/null)
}
