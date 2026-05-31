# {TEAM_NAME}_TEAM_RULE

Rule Version (optional): {VERSION}
Date: {YYYY-MM-DD}
Layer: Team Rule
Owner: {TEAM_LEAD}
Status: Draft / Approved

---

## 0. 位置づけ

この文書は、{TEAM_NAME} におけるAIエージェント運用のTeam Ruleである。

この文書は、Core Rule、Company Rule、Client Rule、Project Ruleの下位に置かれる。上位ルールを緩和または上書きしてはならない。

---

## 1. チーム概要

| 項目 | 内容 |
|---|---|
| チーム名 | {TEAM_NAME} |
| 役割 | {TEAM_ROLE} |
| 主な業務 | {MAIN_WORK} |
| 主な成果物 | {DELIVERABLES} |
| 利用ツール | {TOOLS} |

---

## 2. AIに任せる作業

このチームでは、AIに以下を任せてよい。

- {TASK_1}
- {TASK_2}
- {TASK_3}

AIが自動実行してよい範囲：

- 要約
- 下書き
- 論点整理
- チェックリスト作成
- README / STATUS の軽微更新
- 作業計画案

---

## 3. 人間承認が必要な作業

- 外部送信
- 外部公開
- 顧客への正式回答
- 正本変更
- 権限変更
- 契約、見積、請求に関する確定
- 採用、評価、報酬に関する判断
- 大量ファイル移動
- archive確定
- product化

チーム固有の承認事項：

- {APPROVAL_ITEM_1}
- {APPROVAL_ITEM_2}

---

## 4. 作業フロー

標準フロー：

1. 目的確認
2. 適用ルール確認
3. 作業レベル判定
4. 下書き作成
5. 人間レビュー
6. 必要に応じて修正
7. 承認後に反映
8. README / STATUS / index更新

---

## 5. 出力形式

このチームで好む出力形式：

- 要約: {SUMMARY_STYLE}
- 議事録: {MEETING_STYLE}
- 提案書: {PROPOSAL_STYLE}
- レビュー: {REVIEW_STYLE}
- タスク整理: {TASK_STYLE}

---

## 6. 命名規則

| 対象 | 規則 |
|---|---|
| ディレクトリ | `{DIRECTORY_RULE}` |
| ファイル | `{FILE_RULE}` |
| ブランチ | `{BRANCH_RULE}` |
| Pull Request | `{PR_RULE}` |

---

## 7. レビュー観点

AIエージェントは、成果物を作成・確認する際に以下を見る。

- 目的に合っているか。
- 読み手が明確か。
- 公開範囲に問題がないか。
- 顧客固有情報が混ざっていないか。
- 判断根拠があるか。
- 次のアクションが明確か。
- 上位ルールに違反していないか。

---

## 8. エスカレーション

判断に迷った場合の確認先：

| 内容 | 確認先 |
|---|---|
| 業務判断 | {BUSINESS_APPROVER} |
| 技術判断 | {TECH_APPROVER} |
| 顧客判断 | {CLIENT_APPROVER} |
| 公開判断 | {PUBLIC_APPROVER} |
| 権限判断 | {PERMISSION_APPROVER} |

---

## 9. 改訂

このTeam Ruleは、{TEAM_LEAD} の承認により改訂できる。

AIエージェントは改善案を出せるが、承認なしに正式変更してはならない。
