# workspace-index

Status: Template
Owner: {USER_NAME}
Organization: {COMPANY_NAME}

---

## このファイルの役割

ワークスペース全体の目次・現在地管理。AI と人間が「どこに何があるか」を把握するために使います。

セットアップ時に AI が `core/templates/workspace-index-template.md` を参考に更新します。

---

## 主要領域

| パス | 役割 | 状態 |
|---|---|---|
| `core/` | AgentBase 中核（編集禁止） | managed |
| `rules/` | 組織・個人のルール | user-owned |
| `_inbox/` | 未分類の入口 | active |
| `work/` | 日常業務 | active |
| `presentation/` | 外部向け資料 | active |
| `modules/` | 拡張領域 | optional |

---

## ルールファイル

| ファイル | 階層 | 状態 |
|---|---|---|
| （セットアップ後に記入） | | |

---

## 更新ルール

ディレクトリ作成・移動・archive 時に、この index を更新する。
