# Límits

## Màquina

L'administrador/a tria la mida en crear l'espai i la pot canviar després (reinicia la
màquina; el disc persistent es conserva).

| Mida | CPU | Memòria |
|---|---|---|
| Petita (`e2-medium`), per defecte | 2 vCPU compartides | 4 GB |
| Mitjana (`e2-standard-2`) | 2 vCPU | 8 GB |
| Gran (`e2-standard-4`) | 4 vCPU | 16 GB |

No hi ha GPU.

## Disc

- **Disc persistent** (`/home/teclab` i base de dades): 50 GB per defecte, ampliable fins a
  500 GB. Només pot créixer, mai reduir-se. Ho demana l'administrador/a.
- **Disc del sistema**: 20 GB, efímer: el que hi escrigues fora de `/home/teclab` es perd en
  cada arrancada.

## Temps

- **Aturada per inactivitat**: 30 minuts sense activitat i l'espai s'atura sol.
- **Caducitat**: data prevista de fi del projecte, com a etiqueta. No atura res sola.

## Passarel·la

- **Pressupost de la clau**: entre 1 i 500 dòlars; 20 per defecte. Quan s'esgota, les crides
  fallen fins que l'administrador/a l'amplia (genera una clau nova).
- **Models**: només els de l'accés triat (vegeu [Àlies i models](alies-models.md)).
- Temps màxim d'una crida: 600 segons.

## Xarxa

- Eixida a Internet només cap als dominis permesos (vegeu
  [La xarxa de l'espai](../explicacio/xarxa-de-l-espai.md)).
- Cap connexió entrant. Les apps web es veuen només a través de Coder, amb sessió.
