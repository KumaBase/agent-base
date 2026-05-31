# Workspace Index

Document Version (optional): {VERSION}
Date: {YYYY-MM-DD}
Owner: {OWNER}
Workspace: {WORKSPACE_NAME}

---

## 0. 目的

このファイルは、人間とAIエージェントがワークスペース全体を把握するための地図である。

ディレクトリ作成、移動、_archive、graduated、product化、重要な正本変更が発生した場合は、このファイルを更新する。

---

## 1. Root Documents

| Path | Purpose | Status | Owner | Notes |
|---|---|---|---|---|
| `AI_AGENT_CORE_RULE.md` | 最上位ルール | active | {OWNER} | AI改正不可 |
| `AI_AGENT_RULE_HIERARCHY.md` | ルール階層 | active | {OWNER} |  |
| `{COMPANY}_COMPANY_RULE.md` | 会社基本方針 | active | {OWNER} |  |
| `AI_WORKSPACE_DESIGN.md` | workspace設計 | active | {OWNER} |  |
| `AGENTS.md` | AI実行ルール | active | {OWNER} |  |
| `README.md` | 人間向け説明 | active | {OWNER} |  |

---

## 2. Core Workspace

| Path | Purpose | Status | Owner | Notes |
|---|---|---|---|---|
| `_inbox/` | 未分類の入口 | active | {OWNER} |  |
| `_misc/` | 分類不能だが保持したいもの | active | {OWNER} |  |
| `work/` | 日常業務、議事録、調査、タスク、下書き | active | {OWNER} |  |
| `presentation/` | 人に見せる資料、提案書、営業資料、説明資料 | active | {OWNER} |  |
| `modules/` | 必要に応じて増やす拡張領域 | active | {OWNER} |  |

---

## 3. _inbox

| Path | Summary | Source | Received At | Status | Next Action |
|---|---|---|---|---|---|
| `_inbox/{item}` | {SUMMARY} | {SOURCE} | {DATE} | unclassified | classify |

---

## 4. _misc

| Path | Reason | Review Date | Status | Decision |
|---|---|---|---|---|
| `_misc/{item}` | {REASON} | {YYYY-MM-DD} | holding | keep / move / archive / propose |

---

## 5. work

| Path | Purpose | Status | Owner | Notes |
|---|---|---|---|---|
| `work/{item}` | {PURPOSE} | active / maintained / paused / archived | {OWNER} | {NOTES} |

---

## 6. presentation

| Path | Client / Service / Topic | Purpose | Status | Public Scope | Owner |
|---|---|---|---|---|---|
| `presentation/{path}` | {CLIENT_OR_SERVICE_OR_TOPIC} | {PURPOSE} | draft / review / approved / archived | {SCOPE} | {OWNER} |

---

## 7. modules

| Path | Module | Purpose | Status | Owner |
|---|---|---|---|---|
| `modules/app-dev/` | app-dev | Apps, tools, PoCs, experiments | active / not used | {OWNER} |
| `modules/clients/` | clients | Client-specific information and outputs | active / not used | {OWNER} |
| `modules/departments/` | departments | Department-specific operations and rules | active / not used | {OWNER} |
| `modules/products/` | products | Maintained offerings and products | active / not used | {OWNER} |
| `modules/knowledge/` | knowledge | Reusable knowledge, prompts, kits | active / not used | {OWNER} |
| `modules/automation/` | automation | Automation and AI workflows | active / not used | {OWNER} |

---

## 8. modules/clients

| Path | Client | Purpose | Status | Public Scope | Owner |
|---|---|---|---|---|---|
| `modules/clients/{client-name}` | {CLIENT_NAME} | {PURPOSE} | active / maintained / paused / archived | restricted | {OWNER} |

---

## 9. modules/app-dev

| Path | App / Experiment | Purpose | Status | Graduation Candidate | Owner |
|---|---|---|---|---|---|
| `modules/app-dev/{path}` | {APP_NAME} | {PURPOSE} | idea / prototype / active / paused / archived | yes / no | {OWNER} |

---

## 10. modules/app-dev/_graduated

| Path | Original Path | Successor | Graduated At | Reason | Owner |
|---|---|---|---|---|---|
| `modules/app-dev/_graduated/{app-name}` | `modules/app-dev/apps/{app-name}` | `{repo-or-product}` | {DATE} | {REASON} | {OWNER} |

---

## 11. modules/knowledge

| Path | Purpose | Source | Status | Approved By |
|---|---|---|---|---|
| `modules/knowledge/{item}` | {PURPOSE} | internal / abstracted-from-client / new | draft / approved / archived | {APPROVER} |

---

## 12. modules/products

| Path | Product | Purpose | Status | Owner | Successor / Repo |
|---|---|---|---|---|---|
| `modules/products/{product-name}` | {PRODUCT_NAME} | {PURPOSE} | active / maintained / deprecated / archived | {OWNER} | {LINK} |

---

## 13. _archive

archiveはroot直下に置かず、文脈の近くに置く。

| Path | Original Location | Archived At | Reason | Successor | Owner |
|---|---|---|---|---|---|
| `work/_archive/{item}` | `work/{item}` | {DATE} | {REASON} | {SUCCESSOR} | {OWNER} |
| `presentation/_archive/{item}` | `presentation/{item}` | {DATE} | {REASON} | {SUCCESSOR} | {OWNER} |
| `modules/{module}/_archive/{item}` | `modules/{module}/{item}` | {DATE} | {REASON} | {SUCCESSOR} | {OWNER} |

---

## 14. Compatibility Paths

| Path | Reason | Status | Migration Rule |
|---|---|---|---|
| `{COMPAT_PATH}` | {REASON} | compatibility active / legacy | {MIGRATION_RULE} |

---

## 15. Recent Changes

| Date | Change | Files / Directories | Reason | Approved By |
|---|---|---|---|---|
| {YYYY-MM-DD} | {CHANGE} | {PATHS} | {REASON} | {APPROVER_OR_NA} |

---

## 16. Open Decisions

| Topic | Decision Needed | Owner | Due | Status |
|---|---|---|---|---|
| {TOPIC} | {DECISION} | {OWNER} | {DATE} | open / decided |
