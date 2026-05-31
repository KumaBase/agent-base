# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **ベータ方針**
> AgentBase は **v1.0.0 に到達するまでベータ扱い** です。0.x 系のリリースでは、ルール体系・ディレクトリ構成・`core/` の内容・エージェント指示書が破壊的に変更される可能性があります。GitHub Releases では `--prerelease` で配布されます。
> 利用者は AI に「AgentBase を更新して」と依頼することで、`core/` のみが安全に差し替わります（`rules/`, `work/`, `modules/` 等の利用者領域は触られません）。詳細は [`docs/UPDATE.md`](docs/UPDATE.md) を参照。

## [Unreleased]

- No unreleased changes.

## [0.0.1] - 2026-05-31

### Added

- AgentBase の初期リリース
- `core/rules/AI_AGENT_CORE_RULE.md`（出力側・入力側のセキュリティ、プロンプトインジェクション対策を含む）
- `core/rules/AI_AGENT_RULE_HIERARCHY.md`
- `core/rules/AI_WORKSPACE_DESIGN.md`
- `core/runtime/AGENTS.md`（AI エージェント共通の実行ルール。信頼できない入力ソースの取り扱いを含む）
- `core/templates/` 7 ファイル
  - `company-rule-template.md`
  - `team-rule-template.md`
  - `client-rule-template.md`
  - `project-rule-template.md`
  - `personal-rule-template.md`
  - `workspace-index-template.md`
  - `rule-change-proposal-template.md`
- `core/agent-instructions/` 6 ファイル
  - `INTRODUCE.agent.md`
  - `SETUP.agent.md`
  - `UPDATE.agent.md`
  - `SELF_HEAL.agent.md`
  - `AUTOSYNC.agent.md`
  - `CUSTOMIZE.agent.md`
- `core/DO_NOT_EDIT.md`
- `core/.agent-base-lock.json`（セットアップ時に AI が生成する lock のプレースホルダ）
- ワークスペース骨格
  - `rules/`
  - `_inbox/`
  - `_misc/`
  - `work/`
  - `presentation/`
  - `modules/`
- AI ツール向け入口
  - `AGENTS.md`
  - `CLAUDE.md`
  - `.cursor/rules/agent-base.mdc`
  - `.github/copilot-instructions.md`
  - `GEMINI.md`
  - `.windsurfrules`
  - `.agents/rules/agent-base.md`
  - `.agent/rules/agent-base.md`
- `docs/RULE_LAYERS.md`
- `docs/UPDATE.md`
- `docs/SELF_HEAL.md`
- `workspace-index.md`
- `VERSION` (0.0.1)
- `LICENSE` (MIT)
- `README.md`
- `CHANGELOG.md`
- `.gitignore`, `.gitattributes`

### Notes

- v0.0.1 は 0.x 系の最初のベータです。v1.0.0 に到達するまでは破壊的変更が入る可能性があります（冒頭「ベータ方針」を参照）。
- AgentBase 本体のバージョンは `VERSION` で一元管理します。Core Rule や Runtime など個別ファイルごとのバージョンは持ちません。
- 特定組織固有のルールは AgentBase 本体には含まれません。Instance 側で管理してください。
- 配布物の zip は GitHub Release が自動生成する `Source code (zip)` を利用します。専用 build script は持ちません。
- 展開後フォルダ名がバージョン付きになるため、README では任意のワークスペース名へのリネームを案内します。
