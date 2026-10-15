"""Adaptador de dades: d'on surten les sol·licituds.

`carrega_sollicituds()` retorna sempre la mateixa estructura (llista de diccionaris),
vingui d'on vingui. La font es tria amb la variable d'entorn DATA_SOURCE:

  DATA_SOURCE=csv       (per defecte) llegeix examples/mostra.csv
  DATA_SOURCE=postgres  llegeix la taula `sollicituds` de la base de dades de l'espai
                        (DATABASE_URL, que posa la plantilla de Coder)

Canviar de font és canviar aquesta peça, no l'app. Totes les dades són SINTÈTIQUES: en
entorns d'experiment i demostratius només hi pot haver dades sintètiques o anonimitzades
(ENS mp.sw.1.1; Instrucció 05, apartat 7.2).

Ús:
  python examples/dades.py                        # mostra les sol·licituds de la font triada
  python examples/dades.py --carrega              # copia el CSV a la taula de Postgres
  DATA_SOURCE=postgres python examples/dades.py   # les llegeix de Postgres
"""

import csv
import os
import sys
from pathlib import Path

CSV = Path(__file__).with_name("mostra.csv")
TAULA = "sollicituds"
COLUMNES = ("id", "data", "departament", "tipus", "estat", "import_eur")


def _des_de_csv() -> list[dict]:
    with CSV.open(newline="", encoding="utf-8") as f:
        return [dict(fila) for fila in csv.DictReader(f)]


def _des_de_postgres() -> list[dict]:
    import psycopg  # només cal si la font és Postgres

    with psycopg.connect(os.environ["DATABASE_URL"]) as conn:
        files = conn.execute(
            f"SELECT {', '.join(COLUMNES)} FROM {TAULA} ORDER BY id"
        ).fetchall()
    return [dict(zip(COLUMNES, (str(v) for v in fila))) for fila in files]


ADAPTADORS = {"csv": _des_de_csv, "postgres": _des_de_postgres}


def carrega_sollicituds() -> list[dict]:
    """Retorna les sol·licituds de la font indicada per DATA_SOURCE (csv per defecte)."""
    font = os.environ.get("DATA_SOURCE", "csv")
    if font not in ADAPTADORS:
        raise SystemExit(
            f"DATA_SOURCE={font!r} desconegut; opcions: {', '.join(ADAPTADORS)}"
        )
    return ADAPTADORS[font]()


def carrega_csv_a_postgres() -> int:
    """Crea la taula (si no existeix), la buida i hi copia el CSV. Retorna el nombre de files."""
    import psycopg

    files = _des_de_csv()
    with psycopg.connect(os.environ["DATABASE_URL"]) as conn:
        conn.execute(
            f"""CREATE TABLE IF NOT EXISTS {TAULA} (
                    id integer PRIMARY KEY,
                    data date NOT NULL,
                    departament text NOT NULL,
                    tipus text NOT NULL,
                    estat text NOT NULL,
                    import_eur numeric(10, 2) NOT NULL
                )"""
        )
        conn.execute(f"TRUNCATE {TAULA}")
        with conn.cursor() as cur:
            cur.executemany(
                f"INSERT INTO {TAULA} ({', '.join(COLUMNES)}) VALUES (%s, %s, %s, %s, %s, %s)",
                [tuple(f[c] for c in COLUMNES) for f in files],
            )
    return len(files)


def main() -> int:
    if "--carrega" in sys.argv[1:]:
        if "DATABASE_URL" not in os.environ:
            print("Cal DATABASE_URL (la posa la plantilla de Coder)", file=sys.stderr)
            return 1
        n = carrega_csv_a_postgres()
        print(f"{n} sol·licituds copiades de {CSV.name} a la taula {TAULA}")
        return 0

    font = os.environ.get("DATA_SOURCE", "csv")
    sollicituds = carrega_sollicituds()
    print(f"font: {font}  ·  {len(sollicituds)} sol·licituds")
    for s in sollicituds:
        print(
            f"  #{s['id']}  {s['data']}  {s['departament']:<12} {s['tipus']:<12} "
            f"{s['estat']:<10} {s['import_eur']:>8} €"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
