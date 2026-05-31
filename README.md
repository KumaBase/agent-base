# agent-base

[![Latest release](https://img.shields.io/github/v/release/KumaBase/agent-base?include_prereleases&label=release)](https://github.com/KumaBase/agent-base/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

AI エージェントを安全に自律させるための統治・運用キット。

> **ベータ告知**
> AgentBase は **v1.0.0 に到達するまでベータ扱い** です。0.x 系では仕様・ディレクトリ構成・ルール体系が変わることがあります（[CHANGELOG](CHANGELOG.md)）。
> 新版が出たら AI に **「AgentBase を更新して」** と頼んでください。`core/` だけが差し替わり、あなたの `rules/` や `work/` は触りません（[更新の仕組み](docs/UPDATE.md)）。

## AgentBase は何か

AgentBase は、AI エージェントが会社・顧客・プロジェクト・チーム・個人・タスクの文脈を読み分け、**提案と実行を分離**し、外部作用や破壊的操作を統制しながら働くための運用キットです。

```text
提案は自由。
実行は統制。
探索は広く。
作用は厳格に。
保守的に実行し、創造的に提案する。
```

GitHub Releases の zip を展開すると **そのままワークスペース** として使えます。特定の AI ツールに依存しません。

## 5 分で始める

1. **[最新版をダウンロード](https://github.com/KumaBase/agent-base/releases/latest)** → ページ下部の Assets から `Source code (zip)` をクリック
2. zip を任意の場所に展開し、フォルダを好きな名前にリネーム（例: `my-ai-workspace`）
   - 展開直後のフォルダ名は `agent-base-{version}` 形式になります
3. Cursor / Claude Code / Codex / Copilot / Gemini 等で **そのフォルダを開く**
4. AI に話しかける:

```text
セットアップして
```

AI が組織名・名前を確認し、`rules/` にルールを生成、Git 同期を提案します。

> 既に Git に詳しい方は `git clone https://github.com/KumaBase/agent-base.git my-ai-workspace` でも構いません。安定版として使う場合は Release zip、開発中の最新版を追う場合は clone が向いています。

## ディレクトリ構成

```text
agent-base/                          # = zip 展開後のワークスペース root
├── core/                            # ★ 中核領域（原則編集しない）
│   ├── rules/                       #   中核ルール・階層原則・ワークスペース設計
│   ├── runtime/                     #   実行ルール（AGENTS.md）
│   ├── templates/                   #   ルール雛形
│   ├── agent-instructions/          #   AI 向け操作手順書
│   ├── DO_NOT_EDIT.md
│   └── .agent-base-lock.json
├── rules/                           # ★ あなたのルール（自由に編集）
├── _inbox/                          #   未分類の入口
├── _misc/                           #   分類不能だが保持
├── work/                            #   日常業務
├── presentation/                    #   外部向け資料
├── modules/                         #   拡張領域
├── AGENTS.md                        #   AI 入口（Instance）
├── workspace-index.md
└── docs/                            #   仕組みの説明
```

### `core/` と `rules/` の違い

| | `core/` | `rules/`（root） |
|---|---|---|
| 編集 | 原則しない | 自由 |
| 内容 | 全利用者共通の安全装置 | あなたの組織・個人のルール |
| 更新 | AgentBase 更新で差し替え | あなたが育てる |

## ルール階層

詳細: [`docs/RULE_LAYERS.md`](docs/RULE_LAYERS.md)

```text
中核ルール   → core/rules/AI_AGENT_CORE_RULE.md
組織ルール   → rules/company/
個別ルール   → rules/clients/, rules/projects/, rules/teams/
個人ルール   → rules/personal/
タスク指示   → チャット / rules/tasks/
```

## AI に頼める操作

| 話しかけ方 | 内容 |
|---|---|
| 使い方を教えて / ヘルプ | この AgentBase の概要と操作の案内 |
| セットアップして | 初回カスタマイズ・lock 生成 |
| Git 同期を設定して | git init / remote 設定 |
| 健康診断して | 中核領域の改変検出・修復 |
| AgentBase を更新して | 新版の取り込み |
| ルールを追加して | `rules/` へのカスタマイズ |

## AI が読む順番

各 AI ツールの入口（`CLAUDE.md`, `.cursor/rules/agent-base.mdc`, `.github/copilot-instructions.md`, `GEMINI.md`, `.windsurfrules`, `.agents/`, `.agent/`）はすべて **ルート [`AGENTS.md`](AGENTS.md)** へ誘導されます。`AGENTS.md` には絶対遵守事項と読み込み順が記載されています。

### 必須（毎セッション）

1. [`core/rules/AI_AGENT_CORE_RULE.md`](core/rules/AI_AGENT_CORE_RULE.md)（中核ルール / 最上位）
2. [`core/rules/AI_AGENT_RULE_HIERARCHY.md`](core/rules/AI_AGENT_RULE_HIERARCHY.md)（階層原則）
3. [`core/runtime/AGENTS.md`](core/runtime/AGENTS.md)（実行ルール）

### 該当時

4. `rules/company/*.md`
5. Client / Project / Team Rule
6. `rules/personal/*.md`
7. `core/rules/AI_WORKSPACE_DESIGN.md`
8. `workspace-index.md`
9. 対象 README / STATUS
10. 今回の Task

## 触っていい場所 / 触らない場所

| 触ってよい | 触らない |
|---|---|
| `rules/`, `_inbox/`, `_misc/` | `core/` |
| `work/`, `presentation/`, `modules/` | |
| ルート `AGENTS.md`, `workspace-index.md` | |

## Git について

基本は AI が案内します（`core/agent-instructions/AUTOSYNC.agent.md`）。

- **auto-commit**: 既定は ask（AI が「コミットしますか？」と確認）
- **push**: 明示指示がある場合のみ
- Git に詳しい人は手動操作しても構いません

## 詳しい仕組み

- [ルール階層](docs/RULE_LAYERS.md)
- [更新の仕組み](docs/UPDATE.md)
- [自己修復](docs/SELF_HEAL.md)

## 対応 AI エージェント

Cursor / Claude Code / Codex / GitHub Copilot / Gemini / Antigravity / Windsurf 等。ルート `AGENTS.md` へのポインタで各ツール入口を統一しています。

主な入口ファイル:

- `AGENTS.md`（共通入口）
- `CLAUDE.md`（Claude Code）
- `.cursor/rules/agent-base.mdc`（Cursor）
- `.github/copilot-instructions.md`（GitHub Copilot）
- `GEMINI.md`（Gemini）
- `.windsurfrules`（Windsurf）
- `.agents/rules/agent-base.md` / `.agent/rules/agent-base.md`（Antigravity）

## ライセンス

MIT License — Copyright (c) 2026 Kuma Base 合同会社

## 提供

Kuma Base 合同会社
