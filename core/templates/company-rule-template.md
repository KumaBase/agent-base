# {COMPANY_NAME}_COMPANY_RULE

Rule Version (optional): {VERSION}
Date: {YYYY-MM-DD}
Layer: Company Rule
Owner: {OWNER}
Status: Draft / Approved

---

## 0. 位置づけ

この文書は、{COMPANY_NAME} におけるAIエージェント運用のCompany Ruleである。

この文書は `AI_AGENT_CORE_RULE.md` の下位に置かれる。Core Ruleに違反する内容は無効である。

---

## 1. 会社概要

| 項目 | 内容 |
|---|---|
| 会社名 | {COMPANY_NAME} |
| 事業内容 | {BUSINESS_DESCRIPTION} |
| 主な顧客 | {CUSTOMER_SEGMENTS} |
| 主な成果物 | {DELIVERABLES} |
| AI利用目的 | {AI_USAGE_PURPOSE} |

---

## 2. AI活用方針

{COMPANY_NAME} は、AIを以下の目的で利用する。

- {PURPOSE_1}
- {PURPOSE_2}
- {PURPOSE_3}

中心原則：

```text
提案は自由。
実行は統制。
探索は広く。
作用は厳格に。
```

---

## 3. 人間とAIの役割分担

### AIが担うこと

- 情報整理
- 要約
- 下書き
- 論点整理
- リスク指摘
- 選択肢提示
- 手順化
- 承認後の実行補助

### 人間が担うこと

- 最終判断
- 方針決定
- 顧客への正式回答
- 契約、見積、請求の確定
- 採用、評価、報酬の判断
- 公開判断
- 権限判断

---

## 4. 情報分類

| 分類 | 例 | 原則配置先 | 扱い |
|---|---|---|---|
| 公開可 | 公開済み会社情報 | `shared/` | 再利用可 |
| 社内限定 | 社内手順、運用メモ | `work/` | 外部共有不可 |
| 顧客限定 | 顧客資料、議事録 | `modules/clients/{client}/` | 他顧客流用不可 |
| 個人領域 | 個人メモ、下書き | `rules/personal/` | 共有には本人承認 |
| 機密 | 契約、人事、認証情報 | 限定領域 | 原則AI処理停止または慎重対応 |
| 公開範囲不明 | 未確認資料 | `_inbox/` または限定領域 | 狭く扱う |

---

## 5. 承認ルール

以下は人間承認が必要である。

- 外部送信
- 外部公開
- 権限変更
- 正本変更
- 顧客情報の再利用
- 個人領域から共有領域への移動
- 新規リポジトリ作成
- 大量ファイル移動
- active projectのarchive
- product化
- 契約、見積、請求、採用、評価、報酬の確定

承認者：

| 対象 | 承認者 |
|---|---|
| 会社方針 | {APPROVER_COMPANY} |
| 顧客情報 | {APPROVER_CLIENT} |
| 技術変更 | {APPROVER_TECH} |
| 公開資料 | {APPROVER_PUBLIC} |
| 権限変更 | {APPROVER_PERMISSION} |

---

## 6. ワークスペース方針

推奨構成：

```text
_inbox/
_misc/
work/
presentation/
modules/
  app-dev/
  clients/
  departments/
  products/
  knowledge/
  automation/
workspace-index.md
```

会社固有の追加領域：

- `modules/{CUSTOM_MODULE_1}`: {DESCRIPTION}
- `modules/{CUSTOM_MODULE_2}`: {DESCRIPTION}

---

## 7. 顧客情報の扱い

顧客情報を他顧客向け資料、テンプレート、プロダクト、公開資料にそのまま流用してはならない。

再利用する場合は、以下を行う。

- 顧客名の除去
- 固有名詞の除去
- 数値、契約条件、状況依存情報の抽象化
- 個人情報の除去
- 守秘義務の確認
- 人間承認

---

## 8. template化・product化方針

### template化条件

- 他社でも使える構造である。
- 顧客固有情報を除去できる。
- 繰り返し利用される。
- 導入品質を安定させる。

### product化条件

- 継続提供できる。
- 利用者が明確である。
- 保守・改善が発生する。
- 専用管理が必要である。
- 会社のサービスメニューにできる。

---

## 9. 禁止事項

- Core Ruleの緩和
- 機密情報の無断共有
- 公開範囲の無断拡大
- 顧客情報の無断再利用
- AIによる最終判断の確定
- 承認なしの外部送信、公開、権限変更、正本変更

---

## 10. 改訂

このCompany Ruleは、{APPROVER_COMPANY} の承認により改訂できる。

AIエージェントは改訂案を作成できるが、承認なしに正式変更してはならない。
