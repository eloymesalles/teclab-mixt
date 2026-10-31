# La base de dades de l'espai

Cada espai té un **PostgreSQL 16 amb pgvector** propi, en un contenidor auxiliar (el
**sidecar**) que només l'espai pot veure. Les dades viuen al disc persistent: sobreviuen a
les aturades i desapareixen amb l'espai.

## Connectar-s'hi

Des del terminal, `psql` ja està configurat (variables `PGHOST`, `PGUSER`, `PGPASSWORD`,
`PGDATABASE`):

```bash
psql -c 'select version();'
```

Des de Python, amb `DATABASE_URL`:

```python
import os
import psycopg

with psycopg.connect(os.environ["DATABASE_URL"]) as conn:
    print(conn.execute("select 1").fetchone())
```

Base de dades `app`, usuari `app`, amfitrió `db`. La contrasenya és a l'entorn; no la copies
enlloc.

## Carregar les dades d'exemple

L'adaptador `examples/dades.py` llig les sol·licituds (sintètiques) d'un CSV o de Postgres,
segons `DATA_SOURCE`:

```bash
python examples/dades.py --carrega                  # copia examples/mostra.csv a la taula sollicituds
DATA_SOURCE=postgres python examples/dades.py       # les llig de Postgres
python examples/dades.py                            # les llig del CSV (per defecte)
```

El teu codi hauria de fer el mateix: una peça (l'adaptador) decideix d'on vénen les dades;
l'aplicació no canvia.

## Vectors (pgvector)

L'extensió `vector` és a la imatge del sidecar. Activa-la una vegada a la base `app`:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

Després pots crear columnes `vector(768)` i guardar-hi incrustacions de l'àlies
`embed-default`.

## Eines gràfiques

Hui no hi ha cap eina gràfica per a la base de dades a l'espai. Hi ha una proposta
([issue #17](https://github.com/eloymesalles/teclab-mixt/issues/17)) per a afegir l'extensió
SQLTools a VS Code i `pgweb` com a app; quan estiga, s'actualitzarà esta pàgina.

## Com saber que ha funcionat

- `psql -c 'select 1'` torna una fila amb `1`.
- Després de `--carrega`, `DATA_SOURCE=postgres python examples/dades.py` mostra les mateixes
  sol·licituds que el CSV.
- A la fitxa de l'espai a Coder, l'indicador **Postgres** diu «sana».

## Si falla

- **`connection refused` o `could not translate host name "db"`**: el sidecar encara arranca
  (just després d'engegar l'espai) o ha caigut. Espera un minut; si persisteix, atura i
  engega l'espai.
- **`Cal DATABASE_URL`**: estàs fora de l'espai (per exemple, en un terminal del teu
  ordinador). Estes variables només existeixen dins de l'espai.
- **`permission denied to create extension`**: l'usuari `app` és propietari de la base `app`
  i pot crear l'extensió; si falla, demana a l'administrador/a que ho revise.
- **La taula ha desaparegut**: l'espai s'ha esborrat i recreat, o algú ha executat
  `--carrega` (que buida la taula abans de carregar).

!!! warning "Només dades sintètiques o anonimitzades"
    `mostra.csv` és sintètic. No carregues cap dada real a esta base de dades.
    Vegeu [Dades permeses](../referencia/dades.md).
