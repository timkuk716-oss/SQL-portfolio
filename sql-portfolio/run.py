"""
run.py — запускает все запросы из queries.sql на учебной базе и печатает результаты.

Использует встроенный в Python модуль sqlite3 — НИЧЕГО ставить не нужно.
Запуск:  python run.py
"""
import sqlite3
import re
from pathlib import Path

HERE = Path(__file__).parent


def load_blocks(sql_path: Path):
    """Разбивает queries.sql на блоки по маркеру '-- #N. Заголовок'.
    Возвращает список пар (заголовок, текст_запроса)."""
    text = sql_path.read_text(encoding="utf-8")
    # делим по строкам-маркерам "-- #N. ..." целиком (всю строку убираем)
    parts = re.split(r"(?m)^-- #\d+\..*\n", text)
    titles = re.findall(r"(?m)^-- #\d+\.\s*(.+)$", text)
    blocks = []
    # parts[0] — вступительный комментарий до первого запроса, пропускаем
    for title, body in zip(titles, parts[1:]):
        # убираем строки-комментарии, оставляем сам SQL
        sql = "\n".join(
            line for line in body.splitlines() if not line.strip().startswith("--")
        ).strip()
        if sql:
            blocks.append((title.strip(), sql))
    return blocks


def print_table(columns, rows):
    """Печатает результат запроса простой таблицей."""
    widths = [len(c) for c in columns]
    for row in rows:
        for i, val in enumerate(row):
            widths[i] = max(widths[i], len(str(val)))
    line = " | ".join(c.ljust(widths[i]) for i, c in enumerate(columns))
    print("  " + line)
    print("  " + "-+-".join("-" * w for w in widths))
    for row in rows:
        print("  " + " | ".join(str(v).ljust(widths[i]) for i, v in enumerate(row)))
    print(f"  ({len(rows)} строк)")


def main():
    conn = sqlite3.connect(":memory:")   # база живёт в памяти, на диск ничего не пишем
    cur = conn.cursor()

    # 1) создаём схему и данные
    cur.executescript((HERE / "schema.sql").read_text(encoding="utf-8"))

    # 2) прогоняем все запросы и печатаем результаты
    for title, sql in load_blocks(HERE / "queries.sql"):
        print("\n" + "=" * 70)
        print("►", title)
        print("=" * 70)
        cur.execute(sql)
        columns = [d[0] for d in cur.description]
        rows = cur.fetchall()
        print_table(columns, rows)

    conn.close()


if __name__ == "__main__":
    main()
