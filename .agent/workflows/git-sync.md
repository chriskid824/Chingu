---
description: Git 同步流程 - 推送本地變更並拉取遠端更新
---

# Git 同步流程

## 步驟

// turbo
1. 檢查當前狀態
```bash
cd /Users/chris/Chingu && git status
```

// turbo
2. 暫存所有變更
```bash
git add .
```

3. 提交變更（使用描述性訊息）
```bash
git commit -m "feat: 描述你的變更"
```

// turbo
4. 拉取遠端更新
```bash
git pull --rebase origin main
```

// turbo
5. 推送到遠端
```bash
git push origin main
```

## Commit 訊息規範
- `feat:` 新功能
- `fix:` 修復 Bug
- `refactor:` 重構代碼
- `style:` UI/樣式調整
- `docs:` 文檔更新
- `chore:` 雜項維護

## 衝突處理
如遇衝突：
1. 手動解決衝突檔案
2. `git add .`
3. `git rebase --continue`
