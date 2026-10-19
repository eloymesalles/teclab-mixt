# Exemples

Tots parlen amb la passarel·la LiteLLM (`LITELLM_BASE_URL`, `LITELLM_KEY`) i, els que toquen
dades, amb la base de dades de l'espai (`DATABASE_URL`). Les variables les posa l'entorn
(plantilla de Coder); cap valor incrustat al codi. Només dades sintètiques o anonimitzades.

| Fitxer | Què ensenya |
|---|---|
| `resum.py`, `resum.ipynb` | Una crida al model: resum d'un text, tokens i temps |
| `dades.py` + `mostra.csv` | L'adaptador de dades: `DATA_SOURCE=csv\|postgres`; `--carrega` copia el CSV a la taula |
| `agent.py` | **Agent amb Pydantic AI** (per defecte): eines, sortida estructurada, traces |
| `agent_langgraph.py` | El mateix cas amb **LangGraph**: graf explícit de dos nodes |

```bash
python examples/dades.py --carrega                        # omple la taula sollicituds
python examples/agent.py "quantes sol·licituds hi ha pendents?"
python examples/agent_langgraph.py "quantes sol·licituds hi ha pendents?"
```

## Els models s'invoquen per àlies del catàleg

`LITELLM_MODEL` és un **àlies** de la passarel·la (`chat-default`), no el nom d'un model. A
quin model apunta ho decideix l'administració de la passarel·la (avui `gemini-2.5-flash`):
canviar-lo no toca cap espai ni cap codi. Al registre de LiteLLM el consum surt amb la clau
de l'espai i el model real. Per a un altre model del catàleg, `LITELLM_MODEL=qwen3:8b` (local,
gratuït, lent sense GPU) o qualsevol altre de `GET $LITELLM_BASE_URL/models`.

## Quan Pydantic AI i quan LangGraph

- **Pydantic AI** (per defecte): un agent = un model + eines tipades + una sortida
  estructurada (model Pydantic). L'SDK gestiona el bucle de crides a eines, la validació i els
  reintents. Cobreix la majoria de casos: assistents, extracció, consultes amb eines.
- **LangGraph**: quan el flux ha de ser explícit: estat compartit, bucles amb condició de
  sortida, branques, intervenció humana, execució llarga que es pot aturar i reprendre
  (*checkpoints*). El preu és més codi i més decisions. A `agent_langgraph.py` els dos nodes
  es podrien convertir en un bucle «consultar fins que n'hi hagi prou».
- No hi ha cap SDK de proveïdor (OpenAI Agents SDK, Claude Agent SDK, Google ADK) a la
  imatge: lliguen el projecte a un proveïdor. Si un projecte en necessita un, l'instal·la ell i
  ho justifica a l'Estudi d'Integració.

## Traces OpenTelemetry

`agent.py` instrumenta l'agent amb OpenTelemetry (`Agent.instrument_all()`): cada execució
genera traces amb les crides al model, les eines invocades, els tokens i el temps. Per defecte
no s'exporten enlloc (`OTEL_EXPORTER_OTLP_ENDPOINT` buit: cap error, cap avís). Amb un
col·lector OTLP (Jaeger, Grafana Tempo, Logfire, un *collector* propi):

```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=http://el-collector:4318
python examples/agent.py "..."
```

`OTEL_SERVICE_NAME` el posa la plantilla (`teclab-<propietari>-<espai>`), així les traces
diuen de quin espai venen.

Per què importa: un agent pren decisions (quina eina crida, amb quins arguments, quantes
vegades) que no es veuen al resultat final. Les traces són la **pista d'auditoria** d'aquestes
decisions: reconstruir què ha fet, amb quines dades i quin cost. És el que demana el
requisit **op.exp.8** (registre de l'activitat) de l'ENS per als sistemes en explotació, i el
**control de qualitat** de la Instrucció 04 per a sistemes amb IA: poder revisar el
comportament, no només la sortida. En experiment no cal exportar-les; en preproducció, sí.
