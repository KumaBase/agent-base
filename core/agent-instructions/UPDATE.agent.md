# UPDATE.agent.md

AI エージェント向け指示書。利用者が **「AgentBase を更新して」** と依頼したとき、またはセッション開始時に新版を検知したときに参照する。

---

## 役割

AgentBase 中核（`core/`）を安全に新版へ差し替え、ルート雛形は利用者の改変状況に応じてマージする。

## 手順

### 1. 現バージョンを確認

`core/.agent-base-lock.json` の `version` と `VERSION` ファイルを読む。

### 2. 最新版を確認

GitHub Releases API で `KumaBase/agent-base` の最新版を取得する。

- 同日中の再確認はキャッシュを使い回す（過剰アクセス防止）
- ネットワーク不可時は「確認できませんでした」と伝え、手動更新手順を案内

### 3. 更新不要なら終了

現バージョンが最新なら「最新です（v{version}）」と返して終了。

### 4. 更新内容を提示

`CHANGELOG.md` から日本語要約を提示し、更新可否を確認する。承認なしに進めない。

### 5. 更新実行（承認後）

1. 新版 zip を一時ディレクトリに取得・展開
2. **`core/` サブツリーを丸ごと差し替え**（managed 領域なので安全）
3. ルート雛形（`AGENTS.md`, `.cursor/rules/agent-base.mdc`, `GEMINI.md` 等）は 3-way 判定:
   - 現ファイルの hash が lock の `root_template_hashes` と一致（未改変）→ 新版で静かに上書き
   - 不一致（利用者が改変済み）→ diff を提示し、マージ方針を選ばせる
4. **`rules/`, `work/`, `modules/` 等の利用者領域は触らない**
5. `core/.agent-base-lock.json` を新版で再生成

### 6. Git 記録

Git 同期が有効なら `chore: update agent-base to vX.Y.Z` でコミットする。

- **push は明示指示がある場合のみ**

### 7. 更新レポート

- 旧版 → 新版
- 差し替えた `core/` の概要
- ルート雛形でマージが必要だったファイル
- 推奨アクション（健康診断の実行など）

---

## 禁止事項

- 利用者所有領域（`rules/`, `_inbox/`, `work/` 等）を無断で上書きしない
- push / Release 発行を明示承認なしに実行しない
