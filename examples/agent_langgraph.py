"""El mateix cas que agent.py, resolt amb LangGraph: un graf mínim de dos nodes,
planificar (el model decideix font i filtre) → consultar (es llegeixen les dades i el model
redacta el resum). Referència curta per veure la diferència d'enfocament: aquí l'estat i el
flux són explícits i es poden ampliar amb bucles, branques i execució llarga.

Mateix entorn que agent.py (LITELLM_BASE_URL, LITELLM_KEY, LITELLM_MODEL, DATABASE_URL).
Ús:  python examples/agent_langgraph.py "quantes sol·licituds hi ha pendents?"
"""

import json
import os
import sys
from typing import TypedDict

import dades
from langgraph.graph import END, START, StateGraph
from openai import OpenAI


def entorn(nom: str) -> str:
    valor = os.environ.get(nom, "").strip()
    if not valor:
        raise SystemExit(
            f"Falta la variable d'entorn {nom} (la posa la plantilla de Coder)."
        )
    return valor


client = OpenAI(base_url=entorn("LITELLM_BASE_URL"), api_key=entorn("LITELLM_KEY"))
MODEL = entorn("LITELLM_MODEL")


class Estat(TypedDict, total=False):
    pregunta: str
    font: str  # "postgres" | "csv"
    filtre: str
    files: list[dict]
    resum: str


def planificar(estat: Estat) -> Estat:
    """El model tria la font i el filtre (JSON) a partir de la pregunta."""
    resposta = client.chat.completions.create(
        model=MODEL,
        messages=[
            {
                "role": "system",
                "content": (
                    "Decideix com consultar les sol·licituds. Respon NOMÉS un JSON amb "
                    '"font" ("postgres" per defecte; "csv" només si l\'usuari parla de la '
                    'mostra o del CSV) i "filtre" (text que ha d\'aparèixer en algun camp: '
                    "estat pendent/aprovada/rebutjada, departament, tipus; buit = totes)."
                ),
            },
            {"role": "user", "content": estat["pregunta"]},
        ],
        response_format={"type": "json_object"},
    )
    pla = json.loads(resposta.choices[0].message.content or "{}")
    return {"font": pla.get("font", "postgres"), "filtre": pla.get("filtre", "")}


def consultar(estat: Estat) -> Estat:
    """Llegeix les dades per l'adaptador i fa redactar el resum al model."""
    f = estat.get("filtre", "").strip().lower()
    files = dades.ADAPTADORS[estat.get("font", "postgres")]()
    files = [r for r in files if not f or any(f in str(v).lower() for v in r.values())]
    resposta = client.chat.completions.create(
        model=MODEL,
        messages=[
            {
                "role": "system",
                "content": "Respon la pregunta en català, en una o dues frases, només amb aquestes dades.",
            },
            {
                "role": "user",
                "content": f"Pregunta: {estat['pregunta']}\nDades ({len(files)} files): {json.dumps(files, ensure_ascii=False)}",
            },
        ],
    )
    return {
        "files": files,
        "resum": (resposta.choices[0].message.content or "").strip(),
    }


graf = StateGraph(Estat)
graf.add_node("planificar", planificar)
graf.add_node("consultar", consultar)
graf.add_edge(START, "planificar")
graf.add_edge("planificar", "consultar")
graf.add_edge("consultar", END)
app = graf.compile()


def main(argv: list[str]) -> int:
    if not argv:
        print('Ús: python examples/agent_langgraph.py "pregunta"', file=sys.stderr)
        return 2
    final = app.invoke({"pregunta": " ".join(argv)})
    print(f"Pla:      font={final['font']} filtre={final['filtre']!r}")
    print(f"Resum:    {final['resum']}")
    print(f"Recompte: {len(final['files'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
