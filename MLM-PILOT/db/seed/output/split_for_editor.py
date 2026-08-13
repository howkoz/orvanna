# Split load_seed.sql into SQL-Editor-sized parts (the editor rejects the
# whole 1.7 MB file). Single giant multi-row INSERT statements are re-chunked
# into several INSERT statements of at most CHUNK_ROWS rows so no part
# exceeds roughly PART_BYTES. Each part is wrapped in begin/commit and parts
# must run in numeric order. Date: 2026-08-13.
import re
from pathlib import Path

SRC = Path(__file__).parent / "load_seed.sql"
OUT = Path(__file__).parent / "editor_parts"
OUT.mkdir(exist_ok=True)
PART_BYTES = 400_000
CHUNK_ROWS = 2000

text = SRC.read_text(encoding="utf-8")

# Capture each INSERT statement (header + rows) and the trailing setval block.
insert_re = re.compile(
    r"(insert into [^\n]+ values)\n(.*?);\n", re.DOTALL)
statements = []  # list of (header, [row_lines])
for m in insert_re.finditer(text):
    header = m.group(1)
    rows = [r.rstrip(",") for r in m.group(2).split("\n") if r.strip()]
    statements.append((header, rows))

setvals = [ln for ln in text.split("\n") if ln.startswith("select setval")]

# Emit statements into parts, re-chunking rows, never crossing PART_BYTES.
parts = []
cur = []
cur_bytes = 0

def flush():
    global cur, cur_bytes
    if cur:
        parts.append("\n".join(cur))
        cur = []
        cur_bytes = 0

for header, rows in statements:
    for i in range(0, len(rows), CHUNK_ROWS):
        chunk = rows[i:i + CHUNK_ROWS]
        stmt = header + "\n" + ",\n".join(chunk) + ";"
        if cur_bytes + len(stmt) > PART_BYTES:
            flush()
        cur.append(stmt)
        cur_bytes += len(stmt)

flush()

# setvals ride on a final small part.
parts.append("\n".join(setvals))

for i, body in enumerate(parts, 1):
    content = (f"-- load_seed.sql part {i} of {len(parts)}: run parts IN ORDER.\n"
               "begin;\n" + body + "\ncommit;\n")
    (OUT / f"part_{i}.sql").write_text(content, encoding="utf-8")
    print(f"part_{i}.sql  {len(content):,} bytes")

# The helper bat: feeds the clipboard part by part.
bat = OUT / "LOAD-HELPER.bat"
lines = ["@echo off", "cd /d %~dp0", "echo Orvanna seed loader helper.", "echo."]
for i in range(1, len(parts) + 1):
    lines += [
        f"clip < part_{i}.sql",
        f"echo Part {i} of {len(parts)} is ON YOUR CLIPBOARD.",
        "echo   1. Go to the browser: Supabase SQL Editor.",
        "echo   2. Select all old text (Ctrl+A), paste (Ctrl+V), click Run.",
        "echo   3. Wait for Success, then come back here.",
        "echo.",
        f"pause",
    ]
lines += ["echo ALL PARTS DONE. Tell Fable: loaded.", "pause"]
bat.write_text("\r\n".join(lines), encoding="ascii")
print(f"helper: {bat}")
