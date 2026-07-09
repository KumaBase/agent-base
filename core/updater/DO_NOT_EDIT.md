# DO NOT EDIT

この `core/updater/` 配下は **AgentBase の配布管理下** です。

## 編集してはいけない理由

- アップデータ本体が改変されると、悪意のあるコードが `core/` へ紛れ込む可能性があります。
- チェックサム検証・lock 管理の整合性が壊れます。
- セキュリティ上の重要な安全装置です。

## 壊れた・改変された場合

```
core/updater/self-test.sh
```

または Claude Code で **「健康診断して」** と依頼してください。`core/.agent-base-lock.json` と照合して検出・修復できます。

## 更新方法

```
/core-update
```

または **「AgentBase を更新して」** と AI に依頼してください。
