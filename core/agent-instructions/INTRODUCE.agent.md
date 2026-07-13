# INTRODUCE.agent.md

AI エージェント向け指示書。利用者が **「使い方を教えて」「これは何？」「ヘルプ」「何ができるの？」「最初に何をすればいい？」** などと依頼したとき、またはセッション開始時に未セットアップを検知したときに参照する。

---

## 役割

AgentBase の概要・このワークスペースの現在の状態・依頼できる操作を、利用者にわかりやすく日本語で説明する。

## トリガーとなる発話例

- 「使い方を教えて」
- 「これは何？」
- 「AgentBase って何？」
- 「ヘルプ」
- 「何ができるの？」
- 「どう使うの？」
- 「最初に何をすればいい？」
- 「help」「intro」「about」「what's this」

## 手順

### 1. 現在の状態を確認

- `core/.agent-base-lock.json` の `version` を読む
  - `null` → 未セットアップ
  - 値あり → セットアップ済み（その値を控える）
- `rules/company/`, `rules/personal/` にファイルが存在するかを軽く確認

### 2. 概要を説明

以下の構成に沿って、簡潔（合計 30 行程度を目安）に説明する。README 全文や Core Rule 全文の貼り付けはしない。

#### a. AgentBase は何か（1〜2 行）

AI エージェントが会社・顧客・案件・チーム・個人・タスクの文脈を読み分け、提案と実行を分離して安全に働くための運用キット。

#### b. このワークスペースの状態

- AgentBase バージョン: `VERSION` ファイル または lock の `version`、なければ「未セットアップ」
- ルール状態: Company Rule / Personal Rule の有無
- Git 同期: `.git/` の有無、`origin` の有無

#### c. すぐ依頼できる操作（表）

| 依頼例 | 内容 |
|---|---|
| セットアップして | 初回カスタマイズ・lock 生成 |
| Git 同期を設定して | `git init` / remote 設定 |
| 健康診断して | 中核領域（`core/`）の改変検出・修復 |
| AgentBase を更新して | 新版の取り込み |
| ルールを追加・変更して | `rules/` へのカスタマイズ |
| 専門家チームを呼んで / 会議して | バーチャル専門家チームでの議論・レビュー |
| 使い方を教えて | この案内 |

#### d. 触ってよい場所 / 触らない場所

- 触ってよい: `rules/`, `_inbox/`, `_misc/`, `work/`, `presentation/`, `modules/`, ルート `AGENTS.md`, `workspace-index.md`
- 触らない: `core/`（AgentBase 本体）

#### e. ルール階層（一行で）

中核ルール → 組織ルール → 個別ルール → 個人ルール → タスク指示。詳細は `docs/RULE_LAYERS.md`。

#### f. 困ったとき

- 動作がおかしい → 「健康診断して」
- 設定を変えたい → 「ルールを変えて」
- 新版を取り込みたい → 「AgentBase を更新して」

### 3. 状況に応じた次のステップを提案

- **未セットアップ** → 「『セットアップして』と言うと初期設定が始まります」と案内する。
- **セットアップ済み・Git 未設定** → 「『Git 同期を設定して』をお勧めします」と案内する。
- **すべて整っている** → 「具体的な作業内容を教えてください」と促す。

## 禁止事項

- 長文の貼り付け（README 全文、Core Rule 全文）。
- 不要な英語表現の混在（一次オーディエンスは日本語）。
- 既に把握している情報の再質問。
- 利用者が依頼していない操作（セットアップ、Git 初期化、ファイル生成等）の自動実行。

## 関連

- `core/agent-instructions/SETUP.agent.md`（セットアップ手順）
- `core/agent-instructions/AUTOSYNC.agent.md`（Git 同期）
- `core/agent-instructions/SELF_HEAL.agent.md`（健康診断）
- `core/agent-instructions/UPDATE.agent.md`（更新）
- `core/agent-instructions/CUSTOMIZE.agent.md`（ルール変更）
- `core/agent-instructions/EXPERT_TEAM.agent.md`（バーチャル専門家チーム）
- `README.md`（人間向けの一次ドキュメント）
- `docs/RULE_LAYERS.md`（ルール階層の詳細）
