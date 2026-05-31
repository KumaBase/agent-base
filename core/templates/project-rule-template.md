# {PROJECT_NAME}_PROJECT_RULE

Rule Version (optional): {VERSION}
Date: {YYYY-MM-DD}
Layer: Project Rule
Owner: {PROJECT_OWNER}
Status: Draft / Approved

---

## 0. 位置づけ

この文書は、{PROJECT_NAME} に関するAIエージェント運用のProject Ruleである。

この文書は、Core Rule、Company Rule、Client Ruleの下位に置かれる。上位ルールを緩和してはならない。

---

## 1. プロジェクト概要

| 項目 | 内容 |
|---|---|
| プロジェクト名 | {PROJECT_NAME} |
| 目的 | {PURPOSE} |
| 背景 | {BACKGROUND} |
| Owner | {PROJECT_OWNER} |
| 関係者 | {STAKEHOLDERS} |
| 顧客 | {CLIENT_OR_NONE} |
| 開始日 | {START_DATE} |
| 想定終了日 | {END_DATE_OR_NONE} |
| 現在状態 | active / maintained / paused / archived / moved-to-template / moved-to-product |

---

## 2. スコープ

### 含むもの

- {IN_SCOPE_1}
- {IN_SCOPE_2}
- {IN_SCOPE_3}

### 含まないもの

- {OUT_OF_SCOPE_1}
- {OUT_OF_SCOPE_2}

---

## 3. 成果物

| 成果物 | 保存先 | 状態 |
|---|---|---|
| {DELIVERABLE_1} | {PATH} | draft / review / approved |
| {DELIVERABLE_2} | {PATH} | draft / review / approved |

---

## 4. ディレクトリ構成

```text
{project-path}/
├── PROJECT_RULE.md
├── README.md
├── STATUS.md
├── docs/
├── notes/
├── outputs/
└── _archive/
```

---

## 5. AIに許可する作業

AIエージェントは、このプロジェクトで以下を行ってよい。

- README作成・更新
- STATUS更新
- docs整理
- notes整理
- outputs下書き
- 論点整理
- リスク整理
- タスク分解
- project化 / template化 / product化の提案
- Pull Request説明文の作成

---

## 6. 人間承認が必要な作業

- 外部送信
- 外部公開
- 正本変更
- 顧客提出物の確定
- 大量ファイル移動
- archive確定
- `archived` への状態変更
- `moved-to-template` への状態変更
- `moved-to-product` への状態変更
- product化の実行
- リポジトリ作成
- 権限変更

承認者：{PROJECT_OWNER}

---

## 7. 状態管理

利用可能な状態：

| 状態 | 意味 | AI更新 |
|---|---|---|
| active | 現在進行中 | 可 |
| maintained | 継続利用・保守中 | 可 |
| paused | 一時停止中 | 可 |
| archived | 終了済み・参照用 | 承認必須 |
| moved-to-template | template化済み | 承認必須 |
| moved-to-product | product化済み | 承認必須 |

---

## 8. レビュー観点

- 目的に合っているか。
- スコープを超えていないか。
- 顧客情報を適切に扱っているか。
- 成果物の状態が明確か。
- 次のアクションが明確か。
- README / STATUS / workspace-indexが更新されているか。
- 上位ルールに違反していないか。

---

## 9. template化条件

このプロジェクトが以下を複数満たす場合、AIエージェントはtemplate化を提案できる。

- 他社でも使える構造である。
- 顧客固有情報を除去できる。
- 繰り返し使う可能性がある。
- チェックリスト、手順書、雛形にできる。

---

## 10. product化条件

このプロジェクトが以下を複数満たす場合、AIエージェントはproduct化を提案できる。

- 継続利用されている。
- 利用者が明確である。
- 保守・改善が発生する。
- 専用Issue / Pull Request / Releaseが必要である。
- 導入手順やサポートが必要である。
- 外部提供できる。
- 顧客固有情報を含まない形にできる。

---

## 11. リスク

| リスク | 内容 | 対応 |
|---|---|---|
| {RISK_1} | {DESCRIPTION} | {MITIGATION} |
| {RISK_2} | {DESCRIPTION} | {MITIGATION} |

---

## 12. 改訂

このProject Ruleは、{PROJECT_OWNER} の承認により改訂できる。

AIエージェントは軽微な補足案を作成できるが、承認なしに重要ルールを変更してはならない。
