# CUSTOMIZE.agent.md

AI エージェント向け指示書。利用者が **ルールや運用のカスタマイズ** を依頼したときに参照する。

---

## 役割

`core/` を編集せず、`rules/` と利用者所有領域でカスタマイズを行う。

## 原則

| やりたいこと | 置き場所 |
|---|---|
| 会社方針の追加・変更 | `rules/company/` |
| 顧客・案件・チームの制約 | `rules/clients/`, `rules/projects/`, `rules/teams/` |
| 個人の好み・作業スタイル | `rules/personal/` |
| 今回限りの指示 | チャット、または `rules/tasks/` |
| Core Rule の変更提案 | `core/templates/rule-change-proposal-template.md` を参考に提案書のみ |

## 手順

### 1. 変更対象の階層を特定

`core/rules/AI_AGENT_RULE_HIERARCHY.md` に従い、どの階層のルールか判断する。

### 2. テンプレートから作成または既存を更新

- 新規: `core/templates/` から該当テンプレートを **コピー** して `rules/` 配下に配置
- 更新: 既存 `rules/` ファイルを編集。上位ルールとの整合性を確認

### 3. 上位ルールとの衝突を確認

Core Rule や Company Rule を緩和・迂回する内容は **無効**。安全な代替案を提示する。

### 4. 索引を更新

`workspace-index.md` や該当 README に変更を反映する。

### 5. コミット提案

意味のある区切りで auto-commit（ask モード）を提案する。

---

## 禁止事項

- `core/` 配下の直接編集
- 上位ルールの実質的な無効化
