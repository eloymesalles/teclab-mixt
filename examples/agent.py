"""Exemple d'agent amb Pydantic AI: parla amb la passarel·la LiteLLM pel model de l'àlies
del catàleg i consulta les sol·licituds amb dues eines (base de dades de l'espai o CSV
sintètic, via l'adaptador de dades.py). Resposta estructurada.

Entorn (el posa la plantilla de Coder; cap valor incrustat aquí):
  LITELLM_BASE_URL, LITELLM_KEY   passarel·la
  LITELLM_MODEL                   àlies del catàleg (p. ex. chat-default)
  DATABASE_URL                    base de dades de l'espai (eina consulta_sollicituds)
  OTEL_EXPORTER_OTLP_ENDPOINT     opcional: si té valor, les traces s'exporten per OTLP

Ús:  python examples/agent.py "quantes sol·licituds hi ha pendents?"
"""

import os
import sys

import dades
from openai import AsyncOpenAI
from pydantic import BaseModel, Field
from pydantic_ai import Agent
from pydantic_ai.models.openai import OpenAIChatModel
from pydantic_ai.providers.openai import OpenAIProvider


def entorn(nom: str) -> str:
    valor = os.environ.get(nom, "").strip()
    if not valor:
        raise SystemExit(
            f"Falta la variable d'entorn {nom}. La posa la plantilla de Coder a l'espai "
            "(passarel·la LiteLLM, àlies de model i base de dades)."
        )
    return valor


def model_de_la_passarella() -> OpenAIChatModel:
    """Model de l'àlies del catàleg, servit per la passarel·la (API compatible amb OpenAI)."""
    client = AsyncOpenAI(
        base_url=entorn("LITELLM_BASE_URL"), api_key=entorn("LITELLM_KEY")
    )
    return OpenAIChatModel(
        entorn("LITELLM_MODEL"), provider=OpenAIProvider(openai_client=client)
    )


def instrumenta() -> bool:
    """Traces OpenTelemetry de l'agent (crides al model, eines): exportador OTLP només si hi
    ha endpoint; si no, no s'instal·la res i no hi ha cap avís."""
    if not os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT", "").strip():
        return False
    from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
    from opentelemetry.sdk.trace import TracerProvider
    from opentelemetry.sdk.trace.export import BatchSpanProcessor
    from opentelemetry.trace import set_tracer_provider

    proveidor = TracerProvider()
    proveidor.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
    set_tracer_provider(proveidor)
    Agent.instrument_all()
    return True


class Resultat(BaseModel):
    """Sortida estructurada: el que l'app de l'equip consumiria, no text lliure."""

    resum: str = Field(description="Resposta en català, en una o dues frases")
    recompte: int = Field(
        description="Nombre de sol·licituds en què es basa la resposta"
    )
    font: str = Field(description="D'on surten les dades: 'postgres' o 'csv'")


def _filtra(files: list[dict], filtre: str) -> list[dict]:
    f = filtre.strip().lower()
    if not f:
        return files
    return [r for r in files if any(f in str(v).lower() for v in r.values())]


agent = Agent(
    model_de_la_passarella(),
    output_type=Resultat,
    system_prompt=(
        "Ets un assistent del Teclab. Per respondre sobre sol·licituds, crida SEMPRE una de "
        "les eines i basa't només en el que retornen: consulta_sollicituds (base de dades de "
        "l'espai, la font principal) o consulta_csv (mostra sintètica, només si l'usuari ho "
        "demana). Els estats possibles són: pendent, aprovada, rebutjada. Respon en català."
    ),
)


@agent.tool_plain
def consulta_sollicituds(filtre: str = "") -> list[dict]:
    """Sol·licituds de la base de dades de l'espai (taula sollicituds). `filtre`: text que
    ha d'aparèixer en algun camp (estat, departament, tipus...); buit = totes."""
    return _filtra(dades.ADAPTADORS["postgres"](), filtre)


@agent.tool_plain
def consulta_csv(filtre: str = "") -> list[dict]:
    """Sol·licituds del CSV sintètic de mostra (examples/mostra.csv). Mateix `filtre`."""
    return _filtra(dades.ADAPTADORS["csv"](), filtre)


def main(argv: list[str]) -> int:
    if not argv:
        print(
            'Ús: python examples/agent.py "pregunta en llenguatge natural"',
            file=sys.stderr,
        )
        return 2
    traces = instrumenta()
    resultat = agent.run_sync(" ".join(argv))
    r = resultat.output
    print(f"Resum:    {r.resum}")
    print(f"Recompte: {r.recompte}")
    print(f"Font:     {r.font}")
    us = resultat.usage  # RunUsage (propietat a Pydantic AI 2.x)
    print(
        f"({os.environ['LITELLM_MODEL']} · {us.requests} crides · "
        f"{us.input_tokens} tokens d'entrada, {us.output_tokens} de sortida"
        f"{' · traces OTLP' if traces else ''})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
