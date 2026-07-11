# Chingu 本地 RAG

零依賴(僅 Python 3 內建 sqlite FTS5 trigram)的全文檢索,中文可用。

```bash
python3 tools/rag/rag.py index                       # 重建索引
python3 tools/rag/rag.py search "維持率"              # 檢索(預設 6 筆)
python3 tools/rag/rag.py search -k 10 -t code "配對"  # 只搜程式碼取 10 筆
python3 tools/rag/rag.py search -t doc "雙盲"         # 只搜文件
```

## 涵蓋範圍

- `docs/**/*.md`(含知識庫)、根目錄 `*.md`
- `lib/**/*.dart`、`functions/src/**/*.ts`、`test/**/*.dart`
- 排除 build/node_modules/Pods 等

## 切塊策略

- Markdown 依 `#~###` 標題切塊,保留標題脈絡
- 程式碼每 80 行一塊、重疊 15 行
- 每筆結果附 `檔案:起始行號` 錨點

## 注意

- trigram 需至少 3 字元;中文 2 字詞(如「評價」)請加前後文(如「評價機制」)或改用 grep
- `index.db` 是產物,已加入 .gitignore,不進版控;改完文件/程式後重新 `index`
