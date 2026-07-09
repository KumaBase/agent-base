# DO NOT EDIT

この `core/` ディレクトリは **AgentBase の中核領域** です。

## 編集してはいけない理由

- ここにあるルール・テンプレート・AI 向け手順書は、全利用者共通の安全装置です。
- 直接編集すると、更新・自己修復・ルール階層の整合性が壊れます。
- 変更が必要な場合は、利用者所有の `rules/` 側で上書き・補足してください。

## 保護対象のサブディレクトリ

| パス | 役割 |
|---|---|
| `core/rules/` | 中核ルール（Core Rule, Hierarchy, Workspace Design） |
| `core/runtime/` | 実行ルール |
| `core/templates/` | ルール・index のテンプレート |
| `core/agent-instructions/` | AI 向け手順書（SETUP, UPDATE, SELF_HEAL 等） |
| `core/updater/` | **自動アップデートスクリプト本体**（セキュリティ上重要） |
| `core/git-hooks/` | **Git hooks**（core/ の技術的保護） |

`core/updater/` と `core/git-hooks/` も配布管理下です。改変されると悪意のあるコードが `core/` へ紛れ込む可能性があるため、特に重要です。

## 編集依頼が来たら

AI エージェントは `core/` 配下の編集依頼を **停止** し、次のいずれかを提案します。

1. `rules/company/` や `rules/personal/` に同等の方針を書く
2. `rules/tasks/` に今回限りの個別指示を書く
3. AgentBase 本体の更新を待つ（`core/agent-instructions/UPDATE.agent.md` を参照）

## 壊れた・改変された場合

利用者または AI に **「健康診断して」** と依頼してください。
`core/agent-instructions/SELF_HEAL.agent.md` に従い、`core/.agent-base-lock.json` と照合して復元できます。

技術的検証は `core/updater/self-test.sh` でも実行できます。

## 更新方法

**「AgentBase を更新して」** と AI に依頼するか、Claude Code で `/core-update` を実行してください。
`core/agent-instructions/UPDATE.agent.md` に従い、中核領域だけ安全に差し替えます。
