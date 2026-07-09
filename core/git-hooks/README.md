# core/git-hooks/

AgentBase の `core/` 保護を強化する Git hooks。

## 有効化

```bash
git config core.hooksPath core/git-hooks
```

セットアップ（`core/agent-instructions/SETUP.agent.md`）実行時に案内されます。

## 無効化

```bash
git config --unset core.hooksPath
```

## 含まれる hooks

### commit-msg

`core/` 配下のファイル変更を検知し、以下の例外を除いてブロックします:

1. コミットメッセージが `chore: update agent-base to vX.Y.Z` 形式
   かつ `core/.agent-base-lock.json` がステージされている
2. コミットメッセージが `chore: snapshot before agent-base update`
   （lock.json のステージは不要 — 更新前の dirty 状態を保存する安全ネットのため）

これらは `/core-update` または `apply-update.sh` による公式アップデートとして扱われます。

> `pre-commit` ではなく `commit-msg` を使う理由: git は pre-commit 実行時にコミットメッセージを確定しないため、メッセージベースの公式アップデート判定が確実に行えません。commit-msg はメッセージファイルのパスを `$1` で受け取ります。

## 緊急時の回避

```bash
git commit --no-verify -m "..."
```

`--no-verify` で hooks をバイパスできますが、`core/` の整合性が壊れる可能性があります。自己責任で実行してください。

## 保護の目的

- 誤って `core/` を編集してしまうミスを防ぐ
- 悪意のある AI やスクリプトが `core/` を勝手に書き換えるのを防ぐ
- lock.json との整合性を保つ

## 他の保護層

- `core/DO_NOT_EDIT.md`: ドキュメントレベルの警告
- `core/.agent-base-lock.json`: hash による改変検出
- `core/updater/self-test.sh`: 整合性検証コマンド
- `.github/workflows/integrity.yml`: CI での検証
