#!/usr/bin/env bash
# lock.sh - core/.agent-base-lock.json の読み書き
# 依存: lib/json.sh, lib/hash.sh（jq 不要）

LOCK_PATH="${LOCK_PATH:-core/.agent-base-lock.json}"

# このファイルの位置（source 時に1回だけ評価）
_LOCK_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LOCK_SH_WORKSPACE_ROOT="$(cd "$_LOCK_SH_DIR/../../.." && pwd)"

# json.sh が未ロードならロード
if ! command -v json_get_scalar >/dev/null 2>&1; then
    # shellcheck source=json.sh
    source "$_LOCK_SH_DIR/json.sh"
fi

# lock_path: workspace root からの相対/絶対パスを解決
lock_path() {
    # updater の親2階層が core/。その親が workspace root。
    echo "$_LOCK_SH_WORKSPACE_ROOT/$LOCK_PATH"
}

# lock_exists: lock ファイルが存在するか
lock_exists() {
    [[ -f "$(lock_path)" ]]
}

# lock_get_field <field>
# lock のトップレベルフィールドを取得。未存在・未生成は空文字列。
lock_get_field() {
    local field="$1"
    local lp
    lp="$(lock_path)"
    [[ -f "$lp" ]] || return 0
    json_get_scalar "$lp" "$field"
}

# lock_set_field <field> <value>
# トップレベルフィールドを設定。文字列値として格納。
lock_set_field() {
    local field="$1"
    local value="$2"
    local lp
    lp="$(lock_path)"
    [[ -f "$lp" ]] || return 1
    json_set_scalar "$lp" "$field" "$value" 1
}

# lock_get_version: version フィールド。未設定は空文字。
lock_get_version() {
    lock_get_field "version"
}

# lock_get_source: source URL
lock_get_source() {
    lock_get_field "source"
}

# lock_get_managed_hashes: managed_file_hashes をパスごとに stdout へ
#   "<path>\t<sha256:hex>" 形式
lock_get_managed_hashes() {
    local lp
    lp="$(lock_path)"
    [[ -f "$lp" ]] || return 0
    json_get_object_pairs "$lp" "managed_file_hashes"
}

# lock_get_root_template_hashes: root_template_hashes をパスごとに
lock_get_root_template_hashes() {
    local lp
    lp="$(lock_path)"
    [[ -f "$lp" ]] || return 0
    json_get_object_pairs "$lp" "root_template_hashes"
}

# lock_load_managed_to_file <tmp_file>
# managed_file_hashes を一時ファイルへ "path\tsha256:hex" 形式で出力。
lock_load_managed_to_file() {
    local tmp_file="$1"
    : >"$tmp_file"
    lock_get_managed_hashes >"$tmp_file"
}

# lock_load_root_to_file <tmp_file>
# root_template_hashes を一時ファイルへ "path\tsha256:hex" 形式で出力。
lock_load_root_to_file() {
    local tmp_file="$1"
    : >"$tmp_file"
    lock_get_root_template_hashes >"$tmp_file"
}

# _lock_build_json_object_from_pairs
# stdin から "key\tvalue" 形式を読み込み、JSON オブジェクト文字列を stdout へ。
# 値はすべて文字列として扱う（自動で "..." で囲む）。
# 入力が空なら "{}" を返す。
_lock_build_json_object_from_pairs() {
    local result="{" first=1 k v
    while IFS=$'\t' read -r k v; do
        [[ -z "$k" ]] && continue
        if [[ $first -eq 1 ]]; then
            first=0
        else
            result+=","
        fi
        result+="\"$(json_escape_string "$k")\":\"$(json_escape_string "$v")\""
    done
    result+="}"
    printf '%s' "$result"
}

# lock_regenerate <version> <source_url> [preserve_file]
# core/ と root 雛形を走査し、全 hash を再計算して lock を再生成。
# 現存の installed_at, last_update_check_at は可能なら保持。
#
# preserve_file（任意）: "path\tsha256:hex" 形式。記載された root template
# パスは現ファイルの hash ではなく preserve_file の旧 hash を baseline として
# 記録する。未解決マージ（利用者が改変済みで .new を残した状態）のパス向け。
# これにより次回更新時も「改変あり」と判定され、誤上書きを防ぐ。
lock_regenerate() {
    local new_version="$1"
    local new_source="$2"
    local preserve_file="${3:-}"
    local lp
    lp="$(lock_path)"

    # 既存値の保持
    local installed_at last_check
    installed_at="$(lock_get_field "installed_at")"
    if [[ -z "$installed_at" || "$installed_at" == "null" ]]; then
        installed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    fi
    last_check="$(lock_get_field "last_update_check_at")"
    # last_check を JSON 値（null または "..."）に正規化
    local last_check_json
    if [[ -z "$last_check" || "$last_check" == "null" ]]; then
        last_check_json="null"
    else
        last_check_json="\"$(json_escape_string "$last_check")\""
    fi

    # core/ の hash を収集 → JSON オブジェクト構築
    local workspace_root core_dir
    workspace_root="$_LOCK_SH_WORKSPACE_ROOT"
    core_dir="$workspace_root/core"

    local managed_json
    managed_json="$(hash_compute_dir "$core_dir" | _lock_build_json_object_from_pairs)"
    [[ -n "$managed_json" ]] || managed_json="{}"

    # root_template_hashes を構築
    # preserve_file に記載されたパスは旧 hash（未解決マージの baseline）を保持
    local root_pairs="" p
    while IFS= read -r p; do
        [[ -z "$p" ]] && continue
        local h=""
        # preserve_file に記載があれば旧 hash を優先（未解決マージ保護）
        if [[ -n "$preserve_file" && -f "$preserve_file" ]]; then
            h="$(awk -F '\t' -v path="$p" '$1 == path { print $2; exit }' "$preserve_file" 2>/dev/null)"
        fi
        if [[ -z "$h" ]]; then
            local fp="$workspace_root/$p"
            if [[ -f "$fp" ]]; then
                h="$(hash_compute_sha256 "$fp" 2>/dev/null)" || continue
            else
                continue
            fi
        fi
        if [[ -z "$root_pairs" ]]; then
            root_pairs="${p}"$'\t'"${h}"
        else
            root_pairs+=$'\n'"${p}"$'\t'"${h}"
        fi
    done <<EOF
AGENTS.md
CLAUDE.md
workspace-index.md
.cursor/rules/agent-base.mdc
.github/copilot-instructions.md
GEMINI.md
.windsurfrules
.agents/rules/agent-base.md
.agent/rules/agent-base.md
.claude/settings.json
.claude/hooks/session-start.sh
.claude/skills/core-update/SKILL.md
EOF
    local root_json
    root_json="$(printf '%s\n' "$root_pairs" | _lock_build_json_object_from_pairs)"

    # lock 出力（atomic に書き込み）
    # 構造が固定なので printf テンプレートで構築
    local tmp
    tmp="$(mktemp)"
    {
        printf '{'
        printf '"version":"%s",' "$(json_escape_string "$new_version")"
        printf '"source":"%s",' "$(json_escape_string "$new_source")"
        printf '"installed_at":"%s",' "$(json_escape_string "$installed_at")"
        printf '"last_update_check_at":%s,' "$last_check_json"
        printf '"managed_file_hashes":%s,' "$managed_json"
        printf '"root_template_hashes":%s,' "$root_json"
        printf '"_comment":"SETUP / updater が生成。編集不可。"'
        printf '}\n'
    } >"$tmp"

    # 簡易検証: 先頭が { で末尾が } で始まること
    if [[ -s "$tmp" ]] && head -c1 "$tmp" | grep -q '{' && tail -c2 "$tmp" | grep -q '}'; then
        command mv -f "$tmp" "$lp"
        return 0
    fi
    rm -f "$tmp"
    echo "lock_regenerate: failed to build JSON" >&2
    return 1
}
