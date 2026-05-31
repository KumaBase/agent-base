# Rule Change Proposal

Proposal ID: {YYYYMMDD}-{SHORT_NAME}
Date: {YYYY-MM-DD}
Proposer: {PROPOSER}
Target Layer: Core / Company / Client / Project / Team / Personal / Task
Target File: `{TARGET_FILE}`
Status: Draft / Under Review / Approved / Rejected / Superseded

---

## 1. 変更対象

対象ルール：`{TARGET_FILE}`

対象箇所：

```text
{CURRENT_SECTION_OR_QUOTE}
```

---

## 2. 変更理由

なぜ変更が必要か。

- {REASON_1}
- {REASON_2}
- {REASON_3}

---

## 3. 現行ルール

```md
{CURRENT_RULE_TEXT}
```

---

## 4. 変更案

```md
{PROPOSED_RULE_TEXT}
```

---

## 5. 上位ルールとの整合性

| 観点 | 確認結果 |
|---|---|
| Core Ruleに違反しないか | yes / no / needs review |
| 安全確認を緩和していないか | yes / no / needs review |
| 機密情報保護を緩和していないか | yes / no / needs review |
| 公開範囲拡大を許していないか | yes / no / needs review |
| 外部作用の承認を省略していないか | yes / no / needs review |
| 破壊的操作の制限を緩和していないか | yes / no / needs review |

説明：

{COMPATIBILITY_NOTES}

---

## 6. 影響範囲

影響を受ける範囲：

- {IMPACT_1}
- {IMPACT_2}
- {IMPACT_3}

影響を受けるファイル：

- `{FILE_1}`
- `{FILE_2}`

---

## 7. リスク

| リスク | 内容 | 対応 |
|---|---|---|
| {RISK_1} | {DESCRIPTION} | {MITIGATION} |
| {RISK_2} | {DESCRIPTION} | {MITIGATION} |

---

## 8. rollback方法

変更後に問題があった場合の戻し方：

1. {ROLLBACK_STEP_1}
2. {ROLLBACK_STEP_2}
3. {ROLLBACK_STEP_3}

---

## 9. 承認

| 役割 | 名前 | 承認 | 日付 |
|---|---|---|---|
| Owner | {OWNER} | [ ] | {DATE} |
| Reviewer | {REVIEWER} | [ ] | {DATE} |
| Final Approver | {FINAL_APPROVER} | [ ] | {DATE} |

---

## 10. 実施チェックリスト

- [ ] 変更案を作成した。
- [ ] 上位ルールとの整合性を確認した。
- [ ] 影響範囲を確認した。
- [ ] rollback方法を記載した。
- [ ] 必要な承認を得た。
- [ ] 対象ファイルを更新した。
- [ ] 関連ファイルを更新した。
- [ ] workspace-indexまたは変更ログを更新した。
