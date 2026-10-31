# Dades permeses

## La regla

A l'espai només hi pot haver **dades sintètiques o anonimitzades**. Cap dada de producció,
cap dada personal real, cap document intern que no es puga ensenyar.

És un requisit de l'Esquema Nacional de Seguretat per als entorns de desenvolupament i
experimentació (mesura **mp.sw.1.1**) i de la Instrucció 05 de la UJI (apartat 7.2): cap dada
de producció a desenvolupament.

## Què vol dir a la pràctica

| Sí | No |
|---|---|
| Dades generades (`examples/mostra.csv` n'és un exemple) | Extraccions de bases de dades de la UJI |
| Dades públiques (datasets oberts, documents publicats) | Expedients, actes, correus, llistes de persones |
| Dades reals **anonimitzades** de manera irreversible | Dades «pseudonimitzades» que es puguen tornar a lligar a persones |
| Codi, notebooks, documentació del projecte | Credencials, claus, certificats privats |

Si no tens clar si un conjunt de dades es pot usar, pregunta abans de pujar-lo.

## On viuen les dades

- Al **disc persistent** de l'espai: `/home/teclab` i la base de dades del sidecar. Es
  conserven mentre l'espai existeix.
- A la **passarel·la**: cada crida a un model queda registrada (clau, model, tokens, cost).
  El text de les peticions l'envies tu al proveïdor del model (Google o Amazon, dins de la
  UE): no hi poses res que no vulgues que hi arribe.
- No hi ha còpia de seguretat del disc de l'espai. Esborrar l'espai esborra les dades.

## Si cal treballar amb dades reals

No és el lloc. Un projecte que necessite dades reals ha de passar la porta corresponent del
procediment del Teclab i desplegar-se fora del sandbox. Vegeu
[Cicle de vida d'un espai](../explicacio/cicle-de-vida.md#les-portes).
