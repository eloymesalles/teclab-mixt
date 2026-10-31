# L'agent de codi (Claude Code)

L'espai porta **Claude Code**, un assistent que treballa al terminal sobre els fitxers del
teu projecte: explica codi, proposa canvis, escriu proves, executa ordres. Té dos modes, que
són dos ordres diferents:

| Ordre | Amb què paga | Models | Quan usar-la |
|---|---|---|---|
| `claude` | La **clau del projecte** (pressupost de l'espai) | Els de Claude que la clau té permesos, a través de la passarel·la | Treball del projecte: el consum queda al registre del projecte |
| `claude-compte` | La **llicència de Claude de la UJI** de la teua persona | Els de la teua llicència, directament a Anthropic | Si tens llicència i vols usar-la; el consum no compta al projecte |

## Abans de començar

- `claude` només funciona si l'espai té accés **Gemini i Claude**. Amb «només Gemini» o «cap»,
  l'ordre avisa i ix. Demana el canvi a l'administrador/a si el projecte ho necessita.
- `claude-compte` només funciona si tens una llicència de Claude de la UJI.

## Usar `claude` (passarel·la del projecte)

1. Obri un terminal a l'espai (*Terminal → New Terminal* a VS Code). Ja ets a `~/work`.
2. Executa `claude` per a una sessió interactiva, o passa-li la pregunta directament:

    ```bash
    claude "explica què fa examples/resum.py"
    ```

3. Claude Code demana confirmació abans d'editar un fitxer o executar una ordre. Llig què
   proposa i accepta o rebutja.
4. Per a eixir de la sessió interactiva: `/exit`.

Dins de la sessió, `/model` mostra el model actual. Els àlies `sonnet` i `haiku` apunten als
models de Claude del catàleg de la passarel·la (`claude-sonnet-5.5`, `claude-haiku-5.5`); no
hi ha Opus.

## Usar `claude-compte` (llicència de la UJI)

1. Al terminal, executa `claude-compte`.
2. La primera vegada, escriu `/login`. Mostra una adreça: obri-la al navegador del teu
   ordinador, entra amb el teu compte de Claude i copia el codi que et dóna.
3. Enganxa el codi al terminal. La credencial queda a `~/.claude-compte`, al teu disc
   persistent: no cal repetir-ho mentre l'espai existisca.

Les dos ordres no es barregen: `claude` usa `~/.claude` i `claude-compte` usa
`~/.claude-compte`.

## Com saber que ha funcionat

- `claude "digues hola"` respon amb text; a `/model` apareix un model `claude-…`.
- Al registre de la passarel·la (ho veu l'administrador/a), la crida surt amb la clau del teu
  projecte i el model real.
- Amb `claude-compte`, després de `/login`, `/status` mostra el teu compte.

## Si falla

- **`claude: calen LITELLM_BASE_URL i LITELLM_KEY…`**: l'espai no té clau de projecte. Accés a
  models «cap»: demana'l a l'administrador/a.
- **`claude: cal CLAUDE_MODEL_SONNET…`**: l'espai té clau però sense accés a Claude («només
  Gemini»). Demana l'accés «Gemini i Claude».
- **Error 401/403 en la primera resposta**: la clau no inclou el model, o el pressupost s'ha
  esgotat. Comprova-ho amb `GET /models` (vegeu [Àlies i models](../referencia/alies-models.md)).
- **Error 400 amb un camp desconegut**: una capacitat experimental que la passarel·la no
  admet. Per defecte estan desactivades; si les has activat (`CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=0`),
  torna-les a desactivar.
- **`claude-compte` no obri la pàgina d'entrada**: has d'obrir l'adreça al navegador del teu
  ordinador, no dins de l'espai. L'espai només pot eixir cap als dominis d'Anthropic, no cap a
  qualsevol web.
- **Claude Code proposa instal·lar o actualitzar-se**: no pot; la versió és fixa a la imatge.
  Ignora-ho.

!!! warning "El cost és real"
    Cada torn de `claude` envia a la passarel·la el context de la conversa i els fitxers que
    llig: gasta pressupost del projecte encara que no edite res. Usa `/clear` per a començar
    una conversa nova quan canvies de tema.
