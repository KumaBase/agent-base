# ルール階層（RULE_LAYERS）

AgentBase は「中核ルール → 組織ルール → 個別ルール → 個人ルール → タスク指示」を **ファイル配置と読み順** で表現します。

## 対応表

| 階層 | 名称 | パス |
|---|---|---|
| 中核（最上位） | Core Rule | `core/rules/AI_AGENT_CORE_RULE.md` |
| 中核（最上位） | 階層原則 | `core/rules/AI_AGENT_RULE_HIERARCHY.md` |
| ワークスペース設計 | Workspace Design | `core/rules/AI_WORKSPACE_DESIGN.md` |
| 実行ルール | Runtime | `core/runtime/AGENTS.md` |
| 組織 | Company Rule | `rules/company/{COMPANY}_COMPANY_RULE.md` |
| 顧客 | Client Rule | `rules/clients/{name}/CLIENT_RULE.md` |
| 案件 | Project Rule | `rules/projects/{name}/PROJECT_RULE.md` |
| チーム | Team Rule | `rules/teams/{name}/TEAM_RULE.md` |
| 個人 | Personal Rule | `rules/personal/{NAME}_PERSONAL_RULE.md` |
| タスク | Task Rule | チャット、または `rules/tasks/` |

## 2 つの `rules/` の違い

| パス | 誰が編集するか | 内容 |
|---|---|---|
| `core/rules/` | **編集しない**（AgentBase 本体） | 全利用者共通の中核ルール |
| `rules/`（root） | **あなた / 組織** | 導入先固有のルール |

紛らわしいですが、`core/rules/` = 共通の中核ルール、`rules/` = あなたの組織・個人のルール、と覚えてください。

## 優先順位

```text
Core Rule > Company Rule > Client Rule > Project Rule > Team Rule > Personal Rule > Task Rule
```

詳細は `core/rules/AI_AGENT_RULE_HIERARCHY.md` を参照。

## 読み込み順

ルート `AGENTS.md` の「ルール読み込み順」と同じです。
