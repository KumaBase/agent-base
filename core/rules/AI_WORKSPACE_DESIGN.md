# AI_WORKSPACE_DESIGN

Layer: Workspace Operation Design
Status: Recommended Standard

---

## 0. 目的

この文書は、AIエージェントが安全に作業し、人間が迷わず運用できるワークスペース構造を定義する。

目的は、最初から分類を増やすことではない。rootを安全な作業箱として固定し、日常業務と外部向け成果物を分け、会社や案件ごとの差分は必要になった時点で `modules/` に追加する。

---

## 1. 基本思想

```text
rootは安全な作業箱。
_inboxは入口。
_miscは保留棚。
workは日常業務。
presentationは外に出す成果物。
modulesは必要になったら増やす拡張領域。
archiveは各分類の近くに置く。
```

この設計を **Core Workspace + Optional Modules** と呼ぶ。

AIエージェントは、作業前に配置先、公開範囲、作業レベル、承認要否を判断する。

---

## 2. root固定

AIエージェントが最初に開く場所は、原則としてワークスペースrootに固定する。

```text
{organization}-ai-workspace/
```

root固定の理由は以下である。

- AIが全体ルールを確実に読める。
- 人間が作業場所で迷わない。
- `workspace-index.md` を参照できる。
- ディレクトリ横断で文脈を把握できる。
- GitHub管理を一つの作業単位にまとめられる。
- 誤操作時に履歴から戻しやすい。
- 下層ディレクトリを直接開いてルールが効かない状態を避けられる。

---

## 3. 推奨ディレクトリ構成

```text
ai-workspace/
├── AGENTS.md
├── CLAUDE.md
├── README.md
├── workspace-index.md
├── .claude/
│   ├── settings.json
│   ├── commands/
│   └── agents/
├── _inbox/
├── _misc/
├── work/
├── presentation/
└── modules/
    ├── app-dev/
    ├── clients/
    ├── departments/
    ├── products/
    ├── knowledge/
    └── automation/
```

`modules/*` は最初からすべて作る必要はない。導入先の会社やチームに必要になったものだけを有効化する。

---

## 4. Core Workspace

| Path | 役割 |
|---|---|
| `AGENTS.md` / `CLAUDE.md` | AIが従う最上位の作業ルール |
| `README.md` | 人間向けの入口 |
| `workspace-index.md` | 全体の目次・現在地管理 |
| `_inbox/` | 未分類の入口。迷ったらここ |
| `_misc/` | 分類不能だが残したいもの |
| `work/` | 日常業務。議事録、調査、タスク、下書き |
| `presentation/` | 人に見せる資料。提案書、営業資料、説明資料 |
| `modules/` | 会社や業務に応じた拡張領域 |

---

## 5. `_inbox/`

`_inbox/` は未分類の入口である。

置くもの：

- 新規依頼
- 未分類のメモ
- 素材ファイル
- 整理前の議事録
- 顧客から受け取った未整理資料
- どの領域に属するか判断前の情報

基本方針：

```text
迷ったら _inbox。
ただし、_inbox に置きっぱなしにしない。
```

AIエージェントは、`_inbox/` の内容を見て、適切な配置先、ディレクトリ名、公開範囲、作業レベル、承認要否を提案する。

`_inbox/` から移動する場合は、理由、移動対象、移動先、公開範囲、rollback方法を示す。

---

## 6. `_misc/`

`_misc/` は、分類不能だが保持したいものを置く場所である。

`_misc/` は一時置き場ではない。

```text
_inbox = 未分類の入口
_misc  = 分類不能だが保持したいもの
```

価値がある思想、事業案、記事種、提案材料、再利用可能なフレームは、`_misc/` に置き続けず、`work/`、`presentation/`、または `modules/` へ移す。

削除は人間承認なしに実行してはならない。

---

## 7. `work/`

`work/` は日常業務支援の領域である。

置くもの：

- 会議メモ
- 議事録
- タスク整理
- 調査
- 業務ナレッジ
- 社内整理
- メール、Slack、チャット文面の下書き
- 日々の運用改善

`work/` に置く情報は、成果物そのものというより、業務を前に進めるための作業情報である。

推奨構成：

```text
work/
├── meetings/
├── research/
├── operations/
├── drafts/
├── outputs/
└── _archive/
```

---

## 8. `presentation/`

`presentation/` は、人に見せる資料を管理する領域である。

置くもの：

- 提案書
- 営業資料
- サービス紹介資料
- 登壇資料
- セミナー資料
- 研修資料
- 説明資料
- 資料制作テンプレート
- 画像・図版素材

推奨構成：

```text
presentation/
├── clients/{client-name}/
├── services/{service-name}/
├── slide-decks/
├── templates/
├── assets/
└── _archive/
```

AIエージェントは、資料制作前に目的、対象読者、利用場面、公開範囲、顧客固有情報の有無を確認する。

---

## 9. `modules/`

`modules/` は、会社や業務に応じて必要になった拡張領域を置く場所である。

最初から増やしすぎない。必要なモジュールだけを使う。

| Path | 使う場面 |
|---|---|
| `modules/app-dev/` | アプリ、ツール、PoC、技術検証 |
| `modules/clients/` | 顧客別に管理したい情報がある場合 |
| `modules/departments/` | 部門別に管理したい情報がある場合 |
| `modules/products/` | 自社プロダクト・継続提供物がある場合 |
| `modules/knowledge/` | ナレッジを独立管理したい場合 |
| `modules/automation/` | 自動化・AIワークフローを管理したい場合 |

会社ごとの差分や、rootに置くには大きくなった領域は `modules/` に逃がす。

---

## 10. `modules/app-dev/`

`modules/app-dev/` は、アプリ企画、試作、初期開発、技術検証、PoCの領域である。

本番アプリの永住地ではない。

推奨構成：

```text
modules/app-dev/
├── apps/{app-name}/
├── labs/{experiment-name}/
├── shared-docs/
├── templates/
├── _graduated/
└── _archive/
```

独立を検討する目安：

- 本番ユーザーがいる。
- 本番DBがある。
- 認証を扱う。
- 決済を扱う。
- 個人情報を扱う。
- CI/CDが必要である。
- secrets管理が重要になった。
- 外部開発者が参加する。
- Issue / Pull Request / Releaseを個別管理したい。
- 権限を分けたい。

独立は人間承認なしに実行してはならない。

---

## 11. `modules/clients/`

`modules/clients/` は、顧客別支援情報を管理する領域である。

顧客情報は、他顧客情報、汎用テンプレート、公開資料と混在させてはならない。

推奨構成：

```text
modules/clients/{client-name}/
├── CLIENT_RULE.md
├── README.md
├── STATUS.md
├── meetings/
├── docs/
├── proposals/
├── outputs/
└── _archive/
```

顧客固有情報を他社向け資料やテンプレートへそのまま流用してはならない。

再利用する場合は、匿名化、抽象化、一般化を行い、人間確認を挟む。

---

## 12. `modules/knowledge/`

`modules/knowledge/` は、再利用可能な知識資産を置く領域である。

置くもの：

- 思想
- 事業設計
- AI / prompt design
- 組織設計
- 技術戦略
- 研修・教育フレーム
- テンプレート
- 再利用可能なルール体系

顧客支援で作った成果物をそのまま置いてはならない。再利用できるように、固有名詞、顧客名、数値、契約条件、状況依存情報を除去し、抽象化してから保存する。

---

## 13. `modules/products/`

`modules/products/` は、継続提供する成果物、サービス、ツールを管理する領域である。

置くもの：

- AIエージェント運用キット
- 顧客向け導入パッケージ
- 継続提供するテンプレート群
- 保守・改善が発生するツール
- サービスメニュー化された成果物

推奨構成：

```text
modules/products/{product-name}/
├── README.md
├── STATUS.md
├── docs/
├── templates/
├── examples/
├── releases/
└── _archive/
```

product化は人間承認が必要である。

---

## 14. `modules/automation/`

`modules/automation/` は、自動化やAIワークフローを管理する領域である。

置くもの：

- scripts
- GAS
- 定期実行ジョブ
- AIワークフロー
- データ変換
- 繰り返し作業のパイプライン

外部サービスへの作用、認証情報、APIキー、個人情報を扱う場合は、作業レベルを上げ、人間確認を挟む。

---

## 15. archiveの置き方

archiveはroot直下に置かない。文脈が消えるためである。

archiveは、削除の代替ではなく、作業導線から外すための場所である。

推奨例：

```text
work/_archive/
presentation/_archive/
modules/app-dev/_archive/
modules/clients/{client-name}/_archive/
modules/products/{product-name}/_archive/
```

archiveに入れるもの：

- 完了した案件
- 凍結した企画
- 廃止した試作
- 使わなくなった資料群
- 参照頻度が下がったまとまり

archiveに入れないもの：

- 単なる旧バージョン
- Git履歴で追える過去版
- build成果物
- `node_modules`
- `.env`
- secrets
- 認証情報

---

## 16. `workspace-index.md`

rootには `workspace-index.md` を置く。

役割：

- 現在の全体構成を人間とAIが把握する。
- どこに何があるかを一覧化する。
- 新規作成、移動、archive、graduated、product化時に更新する。
- 属人化を防ぎ、引き継ぎやすくする。
- AIエージェントが置き場所を判断しやすくする。

AIエージェントは、ディレクトリ作成、移動、archive、graduatedを行った場合、`workspace-index.md` の更新を提案または実行する。

---

## 17. GitHub管理方針

GitHubは、単なるファイル置き場ではない。

GitHubは、AIエージェントと人間が協働するための作業基盤である。

基本方針：

- 変更履歴を残す。
- 重要変更はPull Requestで確認する。
- mainへの直接pushは避ける。
- 大量移動、正本変更、product化、archive確定は承認を得る。
- GitHubを大容量ファイル置き場にしない。
- secrets、`.env`、認証情報を保存しない。
- リポジトリは分類ではなく運用単位で分ける。

---

## 18. `.gitignore` 推奨

```gitignore
# secrets
.env
.env.*
*.pem
*.key
credentials/
secrets/

# dependencies
node_modules/
.pnpm-store/
vendor/

# build outputs
dist/
build/
.next/
out/
coverage/

# OS / app
.DS_Store
Thumbs.db

# logs
*.log
logs/

# temporary
tmp/
temp/
.cache/

# local AI tool files
.claude/local/
*.local.md
```

---

## 19. AIエージェントの初動確認

AIエージェントは、依頼を受けたら以下を確認する。

1. 作業領域
2. 作業対象ディレクトリ
3. 読むべきルールファイル
4. 適用されるルール階層
5. 作業レベル L0-L4
6. 新規ディレクトリ作成の要否
7. 移動、編集、削除の要否
8. 人間承認が必要な操作
9. 機密情報、顧客情報、個人情報の有無
10. 最終成果物の置き場所

---

## 20. 非エンジニア向け依頼例

```text
この内容を整理してください。
どこに置くべきか判断し、必要ならディレクトリ作成案を出してください。
まだファイル作成・移動はしないでください。
```

```text
この資料をプレゼン用に整理してください。
適切な配置先を提案してから進めてください。
```

```text
このアプリ案を整理してください。
modules/app-dev 配下で試作するべきか、独立管理を検討すべきか判断してください。
まだ実装はしないでください。
```
