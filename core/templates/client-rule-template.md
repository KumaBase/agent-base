# {CLIENT_NAME}_CLIENT_RULE

Rule Version (optional): {VERSION}
Date: {YYYY-MM-DD}
Layer: Client Rule
Owner: {ACCOUNT_OWNER}
Status: Draft / Approved

---

## 0. 位置づけ

この文書は、{CLIENT_NAME} に関するAIエージェント運用のClient Ruleである。

この文書は、Core RuleとCompany Ruleの下位に置かれる。Project Rule、Team Rule、Personal Rule、Task Ruleよりも、顧客情報、契約、守秘、公開範囲に関して優先される。

---

## 1. 顧客概要

| 項目 | 内容 |
|---|---|
| 顧客名 | {CLIENT_NAME} |
| 業種 | {INDUSTRY} |
| 支援内容 | {SUPPORT_SCOPE} |
| 契約種別 | {CONTRACT_TYPE} |
| 顧客責任者 | {CLIENT_OWNER} |
| 自社責任者 | {ACCOUNT_OWNER} |

---

## 2. 公開範囲

この顧客に関する情報の公開範囲：

```text
{PUBLIC_SCOPE}
```

外部共有可否：

| 情報 | 扱い |
|---|---|
| 顧客名 | {ALLOW_CLIENT_NAME} |
| 事例化 | {ALLOW_CASE_STUDY} |
| 数値 | {ALLOW_NUMBERS} |
| 成果物 | {ALLOW_OUTPUT_REUSE} |
| 契約情報 | 原則不可 |
| 個人情報 | 原則不可 |

---

## 3. 守秘・契約上の制約

- {CONFIDENTIAL_RULE_1}
- {CONFIDENTIAL_RULE_2}
- {CONFIDENTIAL_RULE_3}

AIエージェントは、守秘義務または契約上の制約が不明な場合、公開範囲を広げてはならない。

---

## 4. AIに許可する作業

AIエージェントは、この顧客に関して以下を行ってよい。

- 議事録整理
- 課題整理
- 提案書下書き
- 技術調査
- 業務フロー整理
- FAQ、手順書、README下書き
- リスク整理
- 社内レビュー用の要約

顧客へ直接送信する作業は、承認なしに行ってはならない。

---

## 5. 人間承認が必要な作業

- 顧客への正式回答
- 顧客へのメール、チャット送信
- 提案資料の送付
- 納品物の確定
- 見積、契約、請求に関する文書の確定
- 顧客情報の他社向け再利用
- 顧客情報のtemplate化
- 顧客事例としての利用
- 公開資料への掲載
- 顧客領域から共通領域への移動

承認者：{ACCOUNT_OWNER}

---

## 6. 再利用・テンプレート化

この顧客の情報を再利用する場合は、以下を行う。

- 顧客名の除去
- 固有名詞の除去
- 数値、契約条件、組織事情の抽象化
- 個人情報の除去
- 顧客が特定される表現の除去
- 守秘義務の確認
- {ACCOUNT_OWNER} の承認

再利用可能な要素：

- {REUSABLE_ELEMENT_1}
- {REUSABLE_ELEMENT_2}

再利用不可の要素：

- {NON_REUSABLE_ELEMENT_1}
- {NON_REUSABLE_ELEMENT_2}

---

## 7. ディレクトリ構成

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

---

## 8. レビュー観点

AIエージェントは、顧客関連成果物について以下を確認する。

- 顧客の目的に合っているか。
- 顧客固有情報が適切に扱われているか。
- 公開範囲を超えていないか。
- 未確認事項を断定していないか。
- 提案と確定事項を分けているか。
- 契約、見積、請求に関する確定表現が混ざっていないか。

---

## 9. 改訂

このClient Ruleは、{ACCOUNT_OWNER} の承認により改訂できる。

AIエージェントは改訂案を作成できるが、承認なしに正式変更してはならない。
