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

Ho decideix l'administrador/a a la passarel·la, clau per clau, i ho pot canviar en qualsevol
moment sense tocar l'espai. Un espai nou comença amb els àlies `chat-default`, `chat-llarg`
i `embed-default`; els models de Claude (`claude-haiku-5.5`, `claude-sonnet-5.5`, els que
usa `claude`) s'afegeixen a petició del projecte. Per a comprovar què té la teua clau:

```bash
curl -sS "$LITELLM_BASE_URL/models" -H "Authorization: Bearer $LITELLM_KEY"
```

## Dades i regions

Els models de Gemini s'executen a la regió de Madrid de Google Cloud. Els de Claude
s'executen a Amazon Bedrock amb un perfil que reparteix les peticions només entre regions de
la Unió Europea. En cap cas s'envien dades a fora de la UE per a inferència. Recorda igualment
que a l'espai només hi pot haver dades sintètiques o anonimitzades.
