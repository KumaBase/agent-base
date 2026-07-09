#!/usr/bin/env bash
# github.sh - GitHub Releases API アクセス
# 認証優先順位: gh CLI → GITHUB_TOKEN 環境変数 → 未認証
# 依存: curl, gh (オプション), lib/json.sh

# このファイルの位置
_GITHUB_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# json.sh が未ロードならロード
if ! command -v json_get_scalar >/dev/null 2>&1; then
    # shellcheck source=json.sh
    source "$_GITHUB_SH_DIR/json.sh"
fi

GITHUB_REPO="${GITHUB_REPO:-KumaBase/agent-base}"
GITHUB_API_BASE="${GITHUB_API_BASE:-https://api.github.com}"

# github_auth_header: 認証ヘッダを stdout へ（無ければ空）
# 第1引数に変数名を渡すと "auth_args=()" 配列に設定して返す
# 戻り stdout: "gh" | "token" | "none"
github_detect_auth() {
    # gh CLI の有効な認証
    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        echo "gh"
        return 0
    fi
    # 環境変数トークン
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        echo "token"
        return 0
    fi
    echo "none"
}

# github_curl_args <auth_kind> <array_var>
# curl に渡す認証引数を配列に詰める
github_curl_args() {
    local auth="$1"
    local var="$2"
    eval "$var=()"
    case "$auth" in
        token)
            eval "$var+=( -H \"Authorization: Bearer \$GITHUB_TOKEN\" -H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2022-11-28' )"
            ;;
        none|*)
            eval "$var+=( -H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2022-11-28' )"
            ;;
    esac
}

# _github_semver_gt <a> <b>
# semver a > b なら真(0)。b が空なら a を勝たせる。a が空なら偽。
_github_semver_gt() {
    local a="$1" b="$2"
    [[ -z "$b" ]] && return 0
    [[ -z "$a" ]] && return 1
    local a_major a_minor a_patch b_major b_minor b_patch
    IFS=. read -r a_major a_minor a_patch <<<"$a"
    IFS=. read -r b_major b_minor b_patch <<<"$b"
    a_major=$((10#${a_major:-0})); a_minor=$((10#${a_minor:-0})); a_patch=$((10#${a_patch:-0}))
    b_major=$((10#${b_major:-0})); b_minor=$((10#${b_minor:-0})); b_patch=$((10#${b_patch:-0}))
    (( a_major > b_major )) && return 0
    (( a_major < b_major )) && return 1
    (( a_minor > b_minor )) && return 0
    (( a_minor < b_minor )) && return 1
    (( a_patch > b_patch )) && return 0
    return 1
}

# github_get_latest_release
# 最新リリースの JSON を stdout へ。
# exit 0: 成功
# exit 20: ネットワークエラー / リリース無し
# exit 21: rate limit
#
# 注意: GitHub の /releases/latest は prerelease を除外する。AgentBase は
# 0.x をすべて prerelease 扱いで配布するため、/releases/latest は常に 404 に
# なる。代わりに /releases 一覧を取得し、tag_name を semver 比較で最新を選ぶ。
github_get_latest_release() {
    local auth auth_args
    auth="$(github_detect_auth)"
    github_curl_args "$auth" auth_args

    local url="${GITHUB_API_BASE}/repos/${GITHUB_REPO}/releases?per_page=30"
    local tmp code
    tmp="$(mktemp)"

    # gh CLI がある場合はそれを優先（より高い rate limit）
    if [[ "$auth" == "gh" ]]; then
        if gh api "repos/${GITHUB_REPO}/releases?per_page=30" >"$tmp" 2>/dev/null && [[ -s "$tmp" ]]; then
            : # gh で取得済み
        fi
    fi

    if [[ ! -s "$tmp" ]]; then
        code="$(curl -sS -o "$tmp" -w '%{http_code}' --max-time 10 \
            "${auth_args[@]}" "$url" 2>/dev/null)" || {
            rm -f "$tmp"
            return 20
        }
        case "$code" in
            200) : ;;
            403|429) rm -f "$tmp"; return 21 ;;
            404) rm -f "$tmp"; echo "github_get_latest_release: no releases (404)" >&2; return 20 ;;
            *) rm -f "$tmp"; echo "github_get_latest_release: HTTP $code" >&2; return 20 ;;
        esac
    fi

    # tag_name を全抽出 → semver で最大を選ぶ
    local best_tag="" best_ver="" tag ver
    while IFS= read -r tag; do
        [[ -z "$tag" ]] && continue
        ver="${tag#v}"
        if _github_semver_gt "$ver" "$best_ver"; then
            best_ver="$ver"
            best_tag="$tag"
        fi
    done < <(json_get_top_array_fields "$tmp" "tag_name")
    rm -f "$tmp"

    if [[ -z "$best_tag" ]]; then
        echo "github_get_latest_release: no release tags found" >&2
        return 20
    fi

    # 最新タグの完全なリリース JSON を取得して返す
    github_get_release_by_tag "$best_tag"
}

# github_get_release_by_tag <tag>
# 指定タグのリリース JSON を取得
github_get_release_by_tag() {
    local tag="$1"
    local auth auth_args
    auth="$(github_detect_auth)"
    github_curl_args "$auth" auth_args

    if [[ "$auth" == "gh" ]]; then
        local out
        out="$(gh api "repos/${GITHUB_REPO}/releases/tags/$tag" 2>/dev/null)"
        if [[ $? -eq 0 && -n "$out" ]]; then
            echo "$out"
            return 0
        fi
    fi

    local tmp body code
    tmp="$(mktemp)"
    code="$(curl -sS -o "$tmp" -w '%{http_code}' --max-time 15 \
        "${auth_args[@]}" "${GITHUB_API_BASE}/repos/${GITHUB_REPO}/releases/tags/$tag" 2>/dev/null)" || {
        rm -f "$tmp"
        return 20
    }
    body="$(cat "$tmp" 2>/dev/null)"
    rm -f "$tmp"

    case "$code" in
        200) echo "$body"; return 0 ;;
        403|429) return 21 ;;
        404) return 20 ;;
        *) echo "github_get_release_by_tag: HTTP $code" >&2; return 20 ;;
    esac
}

# github_extract_tag <release_json>
# stdin から release JSON を読み、tag_name を抽出
github_extract_tag() {
    local tmp
    tmp="$(mktemp)"
    cat >"$tmp"
    json_get_scalar "$tmp" "tag_name"
    rm -f "$tmp"
}

# github_extract_zip_url <release_json>
# stdin から release JSON を読み、zipball_url を抽出
github_extract_zip_url() {
    local tmp
    tmp="$(mktemp)"
    cat >"$tmp"
    json_get_scalar "$tmp" "zipball_url"
    rm -f "$tmp"
}

# github_find_asset_url <asset_name>
# stdin から release JSON を読み、指定名の asset の browser_download_url を抽出。無ければ空。
github_find_asset_url() {
    local asset_name="$1"
    local tmp
    tmp="$(mktemp)"
    cat >"$tmp"
    json_find_array_object_field "$tmp" "assets" "name" "$asset_name" "browser_download_url"
    rm -f "$tmp"
}

# github_download <url> <dest>
# URL からファイルをダウンロード。失敗は非ゼロ。
github_download() {
    local url="$1"
    local dest="$2"
    local auth auth_args
    auth="$(github_detect_auth)"
    github_curl_args "$auth" auth_args

    curl -sSL --fail --max-time 60 \
        "${auth_args[@]}" -o "$dest" "$url" 2>/dev/null
}

# github_get_checksums <release_json>
# release の checksums.txt 内容を stdout へ。asset が無い場合は空で exit 10。
github_get_checksums() {
    local release_json="$1"
    local url
    url="$(printf '%s' "$release_json" | github_find_asset_url "checksums.txt")"
    if [[ -z "$url" ]]; then
        return 10
    fi
    local tmp
    tmp="$(mktemp)"
    if ! github_download "$url" "$tmp"; then
        rm -f "$tmp"
        return 20
    fi
    cat "$tmp"
    rm -f "$tmp"
}

# github_get_changelog_section <from_version> <to_version>
# CHANGELOG.md の指定範囲のセクションを取得。
# 外部アクセスはしない。ローカルの CHANGELOG.md を読む。
github_get_changelog_section() {
    local from="$1"
    local to="$2"
    local script_dir workspace_root cl
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    workspace_root="$(cd "$script_dir/../../.." && pwd)"
    cl="$workspace_root/CHANGELOG.md"
    [[ -f "$cl" ]] || return 0

    # to 〜 from のセクションを抽出（簡易）
    # [x.y.z] 見出しで区切る
    awk -v from="$from" -v to="$to" '
        /^## \[/ {
            hdr=$0
            gsub(/^## \[|\].*$/, "", hdr)
            current=hdr
            if (current == to) { p=1; print; next }
            if (current == from) { p=0; exit }
            if (p) { print; next }
            next
        }
        { if (p) print }
    ' "$cl"
}
