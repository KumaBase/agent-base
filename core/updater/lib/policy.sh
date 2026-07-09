#!/usr/bin/env bash
# policy.sh - auto_update_policy の読み取り
# 優先順位:
#   1. rules/personal/*_PERSONAL_RULE.md の auto_update_policy
#   2. .claude/settings.json の auto_update_policy
#   3. デフォルト "auto"
# 依存: lib/json.sh（jq 不要）

_POLICY_SH_DIR=""
# BASH_SOURCE[0] は bash で source 時にスクリプトパスを返す。
# zsh や bash -c では空になる場合があるのでフォールバックも試す。
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    _POLICY_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
fi
# フォールバック: スクリプト自身の $0（直接実行時）
if [[ -z "$_POLICY_SH_DIR" && -n "${0:-}" && "${0}" != *bash* ]]; then
    _POLICY_SH_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
fi
# 最終フォールバック: updater/lib の標準位置を推測
if [[ -z "$_POLICY_SH_DIR" ]]; then
    _guess="$(cd "${0%/*}/core/updater/lib" 2>/dev/null && pwd)"
    [[ -n "$_guess" ]] && _POLICY_SH_DIR="$_guess"
fi
if ! command -v json_get_scalar >/dev/null 2>&1 && [[ -n "$_POLICY_SH_DIR" ]]; then
    # shellcheck source=json.sh
    source "$_POLICY_SH_DIR/json.sh"
fi

POLICY_DEFAULT="${POLICY_DEFAULT:-auto}"

# policy_get_update_policy
# stdout: "auto" | "ask" | "manual" | "compact"
policy_get_update_policy() {
    local script_dir workspace_root
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    workspace_root="$(cd "$script_dir/../../.." && pwd)"

    # 1. Personal Rule を走査（複数あれば最初に見つかったもの優先）
    local pdir="$workspace_root/rules/personal"
    if [[ -d "$pdir" ]]; then
        local f val
        while IFS= read -r -d '' f; do
            val="$(grep -E '^[[:space:]]*auto_update_policy[[:space:]]*:' "$f" 2>/dev/null \
                | head -1 \
                | sed -E 's/^[^:]*:[[:space:]]*//; s/[[:space:]]*$//; s/^"//; s/"$//')"
            if [[ -n "$val" ]]; then
                case "$val" in
                    auto|ask|manual|compact) echo "$val"; return 0 ;;
                esac
            fi
        done < <(find "$pdir" -maxdepth 1 -type f -name '*_PERSONAL_RULE.md' -print0 2>/dev/null)
    fi

    # 2. settings.json
    local settings="$workspace_root/.claude/settings.json"
    if [[ -f "$settings" ]]; then
        local val
        val="$(json_get_scalar "$settings" "auto_update_policy")"
        if [[ -n "$val" ]]; then
            case "$val" in
                auto|ask|manual|compact) echo "$val"; return 0 ;;
            esac
        fi
    fi

    # 3. デフォルト
    echo "$POLICY_DEFAULT"
}

# policy_should_auto_prompt <policy>
# セッション開始時にプロンプトしてよいか
#   auto, ask -> 0 (チェックする)
#   manual, compact -> 1 (スキップ)
policy_should_auto_prompt() {
    local p="$1"
    case "$p" in
        auto|ask) return 0 ;;
        manual|compact) return 1 ;;
        *) return 0 ;;
    esac
}

# policy_get_git_setup_policy
# Git 設定を促すか（ユーザーが意図的に Git を使わない場合は dismissed で抑制）
# stdout: "auto" | "dismissed"
# 優先順位: personal rule → settings.json → デフォルト "auto"
policy_get_git_setup_policy() {
    local script_dir workspace_root
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    workspace_root="$(cd "$script_dir/../../.." && pwd)"

    # 1. Personal Rule を走査
    local pdir="$workspace_root/rules/personal"
    if [[ -d "$pdir" ]]; then
        local f val
        while IFS= read -r -d '' f; do
            val="$(grep -E '^[[:space:]]*git_setup_policy[[:space:]]*:' "$f" 2>/dev/null \
                | head -1 \
                | sed -E 's/^[^:]*:[[:space:]]*//; s/[[:space:]]*$//; s/^"//; s/"$//')"
            if [[ -n "$val" ]]; then
                case "$val" in
                    auto|dismissed) echo "$val"; return 0 ;;
                esac
            fi
        done < <(find "$pdir" -maxdepth 1 -type f -name '*_PERSONAL_RULE.md' -print0 2>/dev/null)
    fi

    # 2. settings.json
    local settings="$workspace_root/.claude/settings.json"
    if [[ -f "$settings" ]]; then
        local val
        val="$(json_get_scalar "$settings" "git_setup_policy")"
        if [[ -n "$val" ]]; then
            case "$val" in
                auto|dismissed) echo "$val"; return 0 ;;
            esac
        fi
    fi

    # 3. デフォルト
    echo "auto"
}
