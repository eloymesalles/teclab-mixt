# Àlies i models

El catàleg de la passarel·la. Els **àlies** són noms estables; el model al qual apunten el
decideix l'administració de la passarel·la i pot canviar.

## Àlies

| Àlies | Model hui | Proveïdor | Ús |
|---|---|---|---|
| `chat-default` | `gemini-2.5-flash` | Vertex AI (Google Cloud, Madrid) | Conversa i tasques generals; ràpid i econòmic |
| `chat-llarg` | `gemini-2.5-pro` | Vertex AI (Google Cloud, Madrid) | Textos llargs, raonament més exigent |
| `embed-default` | `gemini-embedding-001` | Vertex AI (Google Cloud, Madrid) | Incrustacions (vectors) per a cerca semàntica |

## Models pel seu nom

| Nom al catàleg | Proveïdor | Notes |
|---|---|---|
| `gemini-2.5-flash` | Vertex AI | El mateix que `chat-default` |
| `gemini-2.5-pro` | Vertex AI | El mateix que `chat-llarg` |
| `gemini-embedding-001` | Vertex AI | El mateix que `embed-default` |
| `claude-haiku-5.5` | Amazon Bedrock (regions de la UE) | Ràpid i econòmic; el «haiku» de `claude` |
| `claude-sonnet-5.5` | Amazon Bedrock (regions de la UE) | Més capaç; el «sonnet» de `claude` |

## Què pot cridar la teua clau

Depén de l'**accés a models** que l'administrador/a va triar en crear l'espai:

| Accés | Àlies i models disponibles | `claude` per la passarel·la |
|---|---|---|
| Cap | Cap clau: els exemples i `claude` no funcionen | No (sí `claude-compte`) |
| Només Gemini | `chat-default`, `chat-llarg`, `embed-default` | No |
| Gemini i Claude | Els anteriors més `claude-haiku-5.5` i `claude-sonnet-5.5` | Sí |

Per a comprovar-ho:

```bash
curl -sS "$LITELLM_BASE_URL/models" -H "Authorization: Bearer $LITELLM_KEY"
```

## Dades i regions

Els models de Gemini s'executen a la regió de Madrid de Google Cloud. Els de Claude
s'executen a Amazon Bedrock amb un perfil que reparteix les peticions només entre regions de
la Unió Europea. En cap cas s'envien dades a fora de la UE per a inferència. Recorda igualment
que a l'espai només hi pot haver dades sintètiques o anonimitzades.
