#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Chingu 本地 RAG:sqlite FTS5(trigram)全文檢索,支援中文,零外部依賴。

用法:
  python3 tools/rag/rag.py index            # 重建索引(docs/知識庫 + 全部 .md + lib/**.dart + functions)
  python3 tools/rag/rag.py search "維持率"   # 檢索,回傳最相關的段落與出處
  python3 tools/rag/rag.py search -k 10 -t code "配對演算法"   # 只搜程式碼,取前 10 筆

索引策略:
  - Markdown 依標題(##)切塊;程式碼依固定行數(80 行、重疊 15 行)切塊
  - 每塊記錄:檔案路徑、起始行號、類型(doc/code)、標題脈絡
  - trigram tokenizer 讓中文與駝峰式識別字都能子字串比對
"""
import argparse
import os
import re
import sqlite3
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DB_PATH = os.path.join(ROOT, "tools", "rag", "index.db")

DOC_GLOBS = [
    ("docs", ".md"),
    ("", ".md"),  # 根目錄的 *.md(不遞迴)
]
CODE_DIRS = [
    ("lib", (".dart",)),
    ("functions", (".js", ".ts")),
    ("test", (".dart",)),
]
EXCLUDE_DIRS = {"build", ".git", ".dart_tool", "node_modules", "Pods", ".idea", ".vscode"}
CODE_CHUNK_LINES = 80
CODE_CHUNK_OVERLAP = 15


def iter_files():
    # docs/ 底下所有 md(遞迴)
    docs_dir = os.path.join(ROOT, "docs")
    if os.path.isdir(docs_dir):
        for dirpath, dirnames, filenames in os.walk(docs_dir):
            dirnames[:] = [d for d in dirnames if d not in EXCLUDE_DIRS]
            for f in filenames:
                if f.endswith(".md"):
                    yield os.path.join(dirpath, f), "doc"
    # 根目錄 md(不遞迴)
    for f in sorted(os.listdir(ROOT)):
        p = os.path.join(ROOT, f)
        if os.path.isfile(p) and f.endswith(".md"):
            yield p, "doc"
    # 程式碼
    for sub, exts in CODE_DIRS:
        base = os.path.join(ROOT, sub)
        if not os.path.isdir(base):
            continue
        for dirpath, dirnames, filenames in os.walk(base):
            dirnames[:] = [d for d in dirnames if d not in EXCLUDE_DIRS]
            for f in filenames:
                if f.endswith(tuple(exts)):
                    yield os.path.join(dirpath, f), "code"


def chunk_markdown(text):
    """依 ## 標題切塊,保留標題脈絡。回傳 (title, start_line, chunk_text)。"""
    lines = text.splitlines()
    chunks = []
    cur_title, cur_start, cur = "", 1, []
    for i, line in enumerate(lines, 1):
        if re.match(r"^#{1,3} ", line):
            if cur and "".join(cur).strip():
                chunks.append((cur_title, cur_start, "\n".join(cur)))
            cur_title, cur_start, cur = line.lstrip("# ").strip(), i, [line]
        else:
            cur.append(line)
    if cur and "".join(cur).strip():
        chunks.append((cur_title, cur_start, "\n".join(cur)))
    return chunks


def chunk_code(text):
    lines = text.splitlines()
    chunks = []
    i = 0
    while i < len(lines):
        seg = lines[i:i + CODE_CHUNK_LINES]
        if "".join(seg).strip():
            chunks.append(("", i + 1, "\n".join(seg)))
        if i + CODE_CHUNK_LINES >= len(lines):
            break
        i += CODE_CHUNK_LINES - CODE_CHUNK_OVERLAP
    return chunks


def build_index():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)
    db = sqlite3.connect(DB_PATH)
    db.execute(
        "CREATE VIRTUAL TABLE chunks USING fts5("
        "path, kind, title, start_line UNINDEXED, body, tokenize='trigram')"
    )
    n_files, n_chunks = 0, 0
    for path, kind in iter_files():
        try:
            with open(path, encoding="utf-8", errors="ignore") as fh:
                text = fh.read()
        except OSError:
            continue
        rel = os.path.relpath(path, ROOT)
        chunks = chunk_markdown(text) if kind == "doc" else chunk_code(text)
        for title, start, body in chunks:
            db.execute(
                "INSERT INTO chunks (path, kind, title, start_line, body) VALUES (?,?,?,?,?)",
                (rel, kind, title, start, body),
            )
            n_chunks += 1
        n_files += 1
    db.commit()
    db.close()
    print(f"已索引 {n_files} 個檔案、{n_chunks} 個區塊 → {os.path.relpath(DB_PATH, ROOT)}")


def search(query, k=6, kind=None, show_lines=12):
    if not os.path.exists(DB_PATH):
        sys.exit("索引不存在,請先執行: python3 tools/rag/rag.py index")
    db = sqlite3.connect(DB_PATH)
    # trigram 需至少 3 字元;把查詢拆詞後各自加引號避免 FTS 語法錯誤
    terms = [t for t in re.split(r"\s+", query.strip()) if t]
    fts_query = " ".join('"%s"' % t.replace('"', '""') for t in terms)
    sql = ("SELECT path, kind, title, start_line, body, rank FROM chunks "
           "WHERE chunks MATCH ? ")
    params = [fts_query]
    if kind:
        sql += "AND kind = ? "
        params.append(kind)
    sql += "ORDER BY rank LIMIT ?"
    params.append(k)
    try:
        rows = db.execute(sql, params).fetchall()
    except sqlite3.OperationalError as e:
        sys.exit(f"查詢語法錯誤: {e}")
    if not rows:
        print("(無結果 — trigram 需要至少 3 個字元/漢字 2 字詞可加前後文再試)")
        return
    for path, kind_, title, start, body, _ in rows:
        header = f"── {path}:{start}"
        if title:
            header += f"  [{title}]"
        print(header)
        lines = [ln for ln in body.splitlines() if ln.strip()]
        for ln in lines[:show_lines]:
            print("   " + ln[:200])
        if len(lines) > show_lines:
            print(f"   … (共 {len(lines)} 行,見原檔)")
        print()


def main():
    ap = argparse.ArgumentParser(description="Chingu 本地 RAG")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("index", help="重建索引")
    sp = sub.add_parser("search", help="檢索")
    sp.add_argument("query")
    sp.add_argument("-k", type=int, default=6, help="回傳筆數(預設 6)")
    sp.add_argument("-t", "--type", choices=["doc", "code"], default=None, help="限定類型")
    args = ap.parse_args()
    if args.cmd == "index":
        build_index()
    else:
        search(args.query, k=args.k, kind=args.type)


if __name__ == "__main__":
    main()
