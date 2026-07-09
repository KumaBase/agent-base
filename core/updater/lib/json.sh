#!/usr/bin/env bash
# json.sh - 純 bash/awk による JSON 操作（jq 不要）
#
# 本プロジェクトの限定的なスキーマ（lock.json, GitHub API レスポンス）に特化。
# compact（単行）・pretty（整形）両方の JSON を扱うため、awk で文字単位解析する。
# エスケープされたダブルクォート・深いネストはサポートしない。値として扱うのは:
#   - 文字列（制御文字・エスケープなし。パス・ハッシュ・日付・URL）
#   - null
#   - 数値・真偽値（一部）
#
# bash 3.2 互換（連想配列不使用）。

# json_escape_string <string>
# JSON 文字列リテラルとして安全な形へエスケープ。
# stdout: エスケープ済み文字列（クォートは含まない）
json_escape_string() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

# _json_skip_ws <s> <pos_var>
# <pos_var> を先頭の空白で無い文字まで進める。インライン awk は高負荷なので bash の部分文字列で。
_json_skip_ws() {
    local s="$1" posvar="$2"
    local i="${!posvar}"
    local n=${#s}
    local c
    while (( i < n )); do
        c="${s:$i:1}"
        case "$c" in
            ' '|$'\t'|$'\n'|$'\r') i=$((i + 1)) ;;
            *) break ;;
        esac
    done
    eval "$posvar=$i"
}

# json_array_from_file <file>
# ファイルの各行を文字列要素とする JSON 配列を stdout へ。
# 空ファイルなら "[]" を返す。各行は json_escape_string で安全にエスケープ。
json_array_from_file() {
    local file="$1"
    local first=1 line
    printf '['
    if [[ -f "$file" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ $first -eq 1 ]]; then first=0; else printf ','; fi
            printf '"%s"' "$(json_escape_string "$line")"
        done <"$file"
    fi
    printf ']'
}

# json_get_scalar <file> <key>
# トップレベル（コメント: 実際は出現位置最初）のスカラー値を取得。
#   文字列 → クォートを外した値
#   null   → 空文字列
#   その他 → そのまま（"true", "false", "123"）
# 未存在・ファイルなし → 空文字列
json_get_scalar() {
    local file="$1" key="$2"
    [[ -f "$file" ]] || return 0

    awk -v k="$key" '
        { buf = buf $0 "\n" }
        END {
            pat = "\"" k "\"[[:space:]]*:[[:space:]]*"
            if (!match(buf, pat)) exit
            rest = substr(buf, RSTART + RLENGTH)
            c = substr(rest, 1, 1)
            if (c == "\"") {
                # 文字列値: 閉じクォートまで読む
                i = 2
                while (i <= length(rest)) {
                    ch = substr(rest, i, 1)
                    if (ch == "\\") { i += 2; continue }
                    if (ch == "\"") break
                    i++
                }
                # i は閉じクォートの位置。内容は positions 2..i-1
                print substr(rest, 2, i - 2)
            } else {
                # 数値/真偽/null: 区切り文字まで
                i = 1
                while (i <= length(rest)) {
                    ch = substr(rest, i, 1)
                    if (ch == "," || ch == "}" || ch == "]" || ch == " " || ch == "\t" || ch == "\n" || ch == "\r") break
                    i++
                }
                val = substr(rest, 1, i - 1)
                if (val == "null") val = ""
                print val
            }
        }
    ' "$file"
}

# json_get_object_pairs <file> <key>
# 指定キー（オブジェクト）の内容を "subkey\tvalue" 形式で stdout へ。
# 値が文字列ならクォートを外す。null は "null" のまま（文字列として出力）。
json_get_object_pairs() {
    local file="$1" key="$2"
    [[ -f "$file" ]] || return 0

    awk -v k="$key" '
        { buf = buf $0 "\n" }
        END {
            pat = "\"" k "\"[[:space:]]*:[[:space:]]*\\{"
            if (!match(buf, pat)) exit
            # 開始 { の位置
            brace_start = RSTART + RLENGTH - 1
            # 対応する } を探す（ネスト考慮）
            depth = 1
            i = brace_start + 1
            n = length(buf)
            while (i <= n && depth > 0) {
                c = substr(buf, i, 1)
                if (c == "\"") {
                    # 文字列をスキップ
                    i++
                    while (i <= n) {
                        ch = substr(buf, i, 1)
                        if (ch == "\\") { i += 2; continue }
                        if (ch == "\"") { i++; break }
                        i++
                    }
                    continue
                }
                if (c == "{") depth++
                else if (c == "}") { depth--; if (depth == 0) break }
                i++
            }
            block = substr(buf, brace_start + 1, i - brace_start - 1)

            # block 内の "subkey" : value を抽出
            n = length(block)
            pos = 1
            while (pos <= n) {
                # 空白・カンマをスキップ
                while (pos <= n) {
                    c = substr(block, pos, 1)
                    if (c != " " && c != "\t" && c != "\n" && c != "\r" && c != ",") break
                    pos++
                }
                if (pos > n) break
                if (substr(block, pos, 1) != "\"") { pos++; continue }

                # subkey 読み取り
                pos++
                sk_start = pos
                while (pos <= n) {
                    c = substr(block, pos, 1)
                    if (c == "\\") { pos += 2; continue }
                    if (c == "\"") break
                    pos++
                }
                subkey = substr(block, sk_start, pos - sk_start)
                pos++  # 閉じ "

                # 空白スキップ
                while (pos <= n) {
                    c = substr(block, pos, 1)
                    if (c != " " && c != "\t" && c != "\n" && c != "\r") break
                    pos++
                }
                if (substr(block, pos, 1) != ":") { continue }
                pos++  # :
                while (pos <= n) {
                    c = substr(block, pos, 1)
                    if (c != " " && c != "\t" && c != "\n" && c != "\r") break
                    pos++
                }

                # 値読み取り
                c = substr(block, pos, 1)
                if (c == "\"") {
                    pos++
                    val_start = pos
                    while (pos <= n) {
                        ch = substr(block, pos, 1)
                        if (ch == "\\") { pos += 2; continue }
                        if (ch == "\"") break
                        pos++
                    }
                    val = substr(block, val_start, pos - val_start)
                    pos++  # 閉じ "
                } else {
                    val_start = pos
                    while (pos <= n) {
                        ch = substr(block, pos, 1)
                        if (ch == "," || ch == "}" || ch == "]" || ch == " " || ch == "\t" || ch == "\n" || ch == "\r") break
                        pos++
                    }
                    val = substr(block, val_start, pos - val_start)
                }
                print subkey "\t" val
            }
        }
    ' "$file"
}

# json_set_scalar <file> <key> <value> [<is_string>]
# トップレベルのスカラー値を設定。
#   is_string=1（既定）: 値を文字列として "..." で囲む
#   is_string=0: 値をそのまま（null/true/false/数値向け）
json_set_scalar() {
    local file="$1" key="$2" value="$3"
    local is_string="${4:-1}"
    [[ -f "$file" ]] || return 1

    local json_val
    if [[ "$is_string" == "1" ]]; then
        json_val="\"$(json_escape_string "$value")\""
    else
        json_val="$value"
    fi

    local result
    result="$(awk -v k="$key" -v v="$json_val" '
        { buf = buf $0 "\n" }
        END {
            pat = "\"" k "\"[[:space:]]*:[[:space:]]*"
            if (match(buf, pat)) {
                before = substr(buf, 1, RSTART + RLENGTH - 1)
                rest = substr(buf, RSTART + RLENGTH)
                c = substr(rest, 1, 1)
                if (c == "\"") {
                    i = 2
                    while (i <= length(rest)) {
                        ch = substr(rest, i, 1)
                        if (ch == "\\") { i += 2; continue }
                        if (ch == "\"") { i++; break }
                        i++
                    }
                    after = substr(rest, i)
                    printf "%s%s%s", before, v, after
                } else {
                    i = 1
                    while (i <= length(rest)) {
                        ch = substr(rest, i, 1)
                        if (ch == "," || ch == "}" || ch == "]" || ch == " " || ch == "\t" || ch == "\n" || ch == "\r") break
                        i++
                    }
                    after = substr(rest, i)
                    printf "%s%s%s", before, v, after
                }
            } else {
                # 最後の } の前に挿入
                n = length(buf)
                i = n
                while (i > 0) {
                    c = substr(buf, i, 1)
                    if (c != " " && c != "\t" && c != "\n" && c != "\r") break
                    i--
                }
                if (substr(buf, i, 1) != "}") {
                    # 不正: そのまま返す
                    printf "%s", buf
                    exit
                }
                brace_pos = i
                # } の前の非空白文字を探す
                j = brace_pos - 1
                while (j > 0) {
                    c = substr(buf, j, 1)
                    if (c != " " && c != "\t" && c != "\n" && c != "\r") break
                    j--
                }
                last_char = substr(buf, j, 1)
                if (last_char == "{") {
                    # 空オブジェクト: カンマ不要
                    printf "%s\"%s\":%s%s", substr(buf, 1, j), k, v, substr(buf, brace_pos)
                } else {
                    printf "%s,\"%s\":%s%s", substr(buf, 1, j), k, v, substr(buf, brace_pos)
                }
            }
        }
    ' "$file")"

    if [[ -z "$result" ]]; then
        return 1
    fi
    printf '%s\n' "$result" >"$file"
    return 0
}

# json_get_first_array_object_field <file> <array_key> <field_key>
# 指定キー（配列）の最初の要素オブジェクトから、指定フィールドの値を取得。
# GitHub API の assets[0].browser_download_url 等向け。
json_get_first_array_object_field() {
    local file="$1" array_key="$2" field_key="$3"
    [[ -f "$file" ]] || return 0

    awk -v ak="$array_key" -v fk="$field_key" '
        { buf = buf $0 "\n" }
        END {
            # "arraykey" : [ を見つける
            pat = "\"" ak "\"[[:space:]]*:[[:space:]]*\\["
            if (!match(buf, pat)) exit
            rest = substr(buf, RSTART + RLENGTH)
            n = length(rest)
            pos = 1
            # 最初の { を探す
            while (pos <= n) {
                c = substr(rest, pos, 1)
                if (c == "]") exit  # 空配列
                if (c == "{") break
                pos++
            }
            if (pos > n) exit
            obj_start = pos
            # 対応する } を探す
            depth = 1
            i = obj_start + 1
            while (i <= n && depth > 0) {
                c = substr(rest, i, 1)
                if (c == "\"") {
                    i++
                    while (i <= n) {
                        ch = substr(rest, i, 1)
                        if (ch == "\\") { i += 2; continue }
                        if (ch == "\"") { i++; break }
                        i++
                    }
                    continue
                }
                if (c == "{") depth++
                else if (c == "}") { depth--; if (depth == 0) break }
                i++
            }
            obj = substr(rest, obj_start + 1, i - obj_start - 1)

            # obj 内の "fieldkey" : value を探す
            on = length(obj)
            opos = 1
            while (opos <= on) {
                while (opos <= on) {
                    c = substr(obj, opos, 1)
                    if (c != " " && c != "\t" && c != "\n" && c != "\r" && c != ",") break
                    opos++
                }
                if (opos > on) break
                if (substr(obj, opos, 1) != "\"") { opos++; continue }
                opos++
                k_start = opos
                while (opos <= on) {
                    c = substr(obj, opos, 1)
                    if (c == "\\") { opos += 2; continue }
                    if (c == "\"") break
                    opos++
                }
                fkey = substr(obj, k_start, opos - k_start)
                opos++
                while (opos <= on) {
                    c = substr(obj, opos, 1)
                    if (c != " " && c != "\t" && c != "\n" && c != "\r") break
                    opos++
                }
                if (substr(obj, opos, 1) != ":") { continue }
                opos++
                while (opos <= on) {
                    c = substr(obj, opos, 1)
                    if (c != " " && c != "\t" && c != "\n" && c != "\r") break
                    opos++
                }
                c = substr(obj, opos, 1)
                if (c == "\"") {
                    opos++
                    v_start = opos
                    while (opos <= on) {
                        ch = substr(obj, opos, 1)
                        if (ch == "\\") { opos += 2; continue }
                        if (ch == "\"") break
                        opos++
                    }
                    fval = substr(obj, v_start, opos - v_start)
                    opos++
                } else {
                    v_start = opos
                    while (opos <= on) {
                        ch = substr(obj, opos, 1)
                        if (ch == "," || ch == "}" || ch == "]" || ch == " " || ch == "\t" || ch == "\n" || ch == "\r") break
                        opos++
                    }
                    fval = substr(obj, v_start, opos - v_start)
                }
                if (fkey == fk) {
                    print fval
                    exit
                }
            }
        }
    ' "$file"
}

# json_get_top_array_fields <file> <field_key>
# トップレベルが配列の JSON から、各オブジェクトの <field_key> 値を
# 1行1個で stdout へ出力。GitHub /releases 一覧の tag_name 抽出等向け。
# 値が文字列ならクォートを外す。見つからないオブジェクトはスキップ。
json_get_top_array_fields() {
    local file="$1" field_key="$2"
    [[ -f "$file" ]] || return 0

    awk -v fk="$field_key" '
        { buf = buf $0 "\n" }
        END {
            n = length(buf)
            # 最初の [ を探す
            pos = 1
            while (pos <= n) {
                c = substr(buf, pos, 1)
                if (c == "[") break
                pos++
            }
            if (pos > n) exit
            rest = substr(buf, pos + 1)
            rn = length(rest)
            rpos = 1
            while (rpos <= rn) {
                while (rpos <= rn) {
                    c = substr(rest, rpos, 1)
                    if (c != " " && c != "\t" && c != "\n" && c != "\r" && c != ",") break
                    rpos++
                }
                if (rpos > rn) break
                c = substr(rest, rpos, 1)
                if (c == "]") break
                if (c != "{") { rpos++; continue }
                obj_start = rpos
                depth = 1
                i = obj_start + 1
                while (i <= rn && depth > 0) {
                    c = substr(rest, i, 1)
                    if (c == "\"") {
                        i++
                        while (i <= rn) {
                            ch = substr(rest, i, 1)
                            if (ch == "\\") { i += 2; continue }
                            if (ch == "\"") { i++; break }
                            i++
                        }
                        continue
                    }
                    if (c == "{") depth++
                    else if (c == "}") { depth--; if (depth == 0) break }
                    i++
                }
                obj = substr(rest, obj_start + 1, i - obj_start - 1)
                rpos = i + 1

                # obj 内の field_key を探す
                on = length(obj)
                opos = 1
                while (opos <= on) {
                    while (opos <= on) {
                        c = substr(obj, opos, 1)
                        if (c != " " && c != "\t" && c != "\n" && c != "\r" && c != ",") break
                        opos++
                    }
                    if (opos > on) break
                    if (substr(obj, opos, 1) != "\"") { opos++; continue }
                    opos++
                    k_start = opos
                    while (opos <= on) {
                        c = substr(obj, opos, 1)
                        if (c == "\\") { opos += 2; continue }
                        if (c == "\"") break
                        opos++
                    }
                    fkey = substr(obj, k_start, opos - k_start)
                    opos++
                    while (opos <= on) {
                        c = substr(obj, opos, 1)
                        if (c != " " && c != "\t" && c != "\n" && c != "\r") break
                        opos++
                    }
                    if (substr(obj, opos, 1) != ":") { continue }
                    opos++
                    while (opos <= on) {
                        c = substr(obj, opos, 1)
                        if (c != " " && c != "\t" && c != "\n" && c != "\r") break
                        opos++
                    }
                    c = substr(obj, opos, 1)
                    if (c == "\"") {
                        opos++
                        v_start = opos
                        while (opos <= on) {
                            ch = substr(obj, opos, 1)
                            if (ch == "\\") { opos += 2; continue }
                            if (ch == "\"") break
                            opos++
                        }
                        fval = substr(obj, v_start, opos - v_start)
                        opos++
                    } else {
                        v_start = opos
                        while (opos <= on) {
                            ch = substr(obj, opos, 1)
                            if (ch == "," || ch == "}" || ch == "]" || ch == " " || ch == "\t" || ch == "\n" || ch == "\r") break
                            opos++
                        }
                        fval = substr(obj, v_start, opos - v_start)
                    }
                    if (fkey == fk) {
                        print fval
                        break
                    }
                }
            }
        }
    ' "$file"
}

# json_find_array_object_field <file> <array_key> <match_key> <match_value> <return_key>
# 配列内の全オブジェクトを走査し、<match_key> == <match_value> のオブジェクトから
# <return_key> の値を取得。GitHub API の assets から名前で asset を探す等向け。
# 見つからなければ空文字列。
json_find_array_object_field() {
    local file="$1" array_key="$2" match_key="$3" match_val="$4" return_key="$5"
    [[ -f "$file" ]] || return 0

    awk -v ak="$array_key" -v mk="$match_key" -v mv="$match_val" -v rk="$return_key" '
        { buf = buf $0 "\n" }
        END {
            pat = "\"" ak "\"[[:space:]]*:[[:space:]]*\\["
            if (!match(buf, pat)) exit
            rest = substr(buf, RSTART + RLENGTH)
            n = length(rest)
            pos = 1
            # 配列内の各 { ... } を順に処理
            while (pos <= n) {
                # 空白スキップ
                while (pos <= n) {
                    c = substr(rest, pos, 1)
                    if (c != " " && c != "\t" && c != "\n" && c != "\r" && c != ",") break
                    pos++
                }
                if (pos > n) break
                c = substr(rest, pos, 1)
                if (c == "]") exit  # 配列終了
                if (c != "{") { pos++; continue }
                # オブジェクト抽出
                obj_start = pos
                depth = 1
                i = obj_start + 1
                while (i <= n && depth > 0) {
                    c = substr(rest, i, 1)
                    if (c == "\"") {
                        i++
                        while (i <= n) {
                            ch = substr(rest, i, 1)
                            if (ch == "\\") { i += 2; continue }
                            if (ch == "\"") { i++; break }
                            i++
                        }
                        continue
                    }
                    if (c == "{") depth++
                    else if (c == "}") { depth--; if (depth == 0) break }
                    i++
                }
                obj = substr(rest, obj_start + 1, i - obj_start - 1)
                pos = i + 1

                # obj 内で mk == mv のオブジェクトか判定しつつ rk の値を探す
                on = length(obj)
                opos = 1
                match_found = 0
                ret_val = ""
                ret_found = 0
                while (opos <= on) {
                    while (opos <= on) {
                        c = substr(obj, opos, 1)
                        if (c != " " && c != "\t" && c != "\n" && c != "\r" && c != ",") break
                        opos++
                    }
                    if (opos > on) break
                    if (substr(obj, opos, 1) != "\"") { opos++; continue }
                    opos++
                    k_start = opos
                    while (opos <= on) {
                        c = substr(obj, opos, 1)
                        if (c == "\\") { opos += 2; continue }
                        if (c == "\"") break
                        opos++
                    }
                    fkey = substr(obj, k_start, opos - k_start)
                    opos++
                    while (opos <= on) {
                        c = substr(obj, opos, 1)
                        if (c != " " && c != "\t" && c != "\n" && c != "\r") break
                        opos++
                    }
                    if (substr(obj, opos, 1) != ":") { continue }
                    opos++
                    while (opos <= on) {
                        c = substr(obj, opos, 1)
                        if (c != " " && c != "\t" && c != "\n" && c != "\r") break
                        opos++
                    }
                    c = substr(obj, opos, 1)
                    if (c == "\"") {
                        opos++
                        v_start = opos
                        while (opos <= on) {
                            ch = substr(obj, opos, 1)
                            if (ch == "\\") { opos += 2; continue }
                            if (ch == "\"") break
                            opos++
                        }
                        fval = substr(obj, v_start, opos - v_start)
                        opos++
                    } else {
                        v_start = opos
                        while (opos <= on) {
                            ch = substr(obj, opos, 1)
                            if (ch == "," || ch == "}" || ch == "]" || ch == " " || ch == "\t" || ch == "\n" || ch == "\r") break
                            opos++
                        }
                        fval = substr(obj, v_start, opos - v_start)
                    }
                    if (fkey == mk && fval == mv) match_found = 1
                    if (fkey == rk) { ret_val = fval; ret_found = 1 }
                }
                if (match_found && ret_found) {
                    print ret_val
                    exit
                }
            }
        }
    ' "$file"
}
