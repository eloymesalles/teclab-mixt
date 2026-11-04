# Mostrar una app web

Si el teu projecte té una interfície web (Streamlit, Gradio, FastAPI, Flask…), l'espai la
mostra amb el botó **App** de la fitxa de Coder, en una adreça pròpia, i tu decideixes qui la
pot obrir. No és una manera de servir-la: l'app només existeix mentre l'espai és engegat i tu
l'has llançada.

## Com funciona

Cada espai té una adreça reservada per a la seua app:

```text
https://app--<espai>--<usuari>.plataforma.teclab.uji.es
```

Coder la reenvia cap a un port de l'espai. El contracte que ha de complir la teua app és un
de sol: **escoltar a `127.0.0.1` al port que diu la variable `APP_PORT`** (`8080` si no l'has
canviat). No cal cap prefix de ruta ni cap configuració especial del marc.

## Passos

1. Llança l'app escoltant al port d'`APP_PORT`, **des de la carpeta del projecte**
   (`cd ~/work/<projecte>`). Exemple amb Streamlit:

    ```bash
    streamlit run app.py --server.address 127.0.0.1 --server.port "$APP_PORT"
    ```

    Compte amb els servidors que serveixen fitxers (`python -m http.server`, per exemple):
    mostren tot el que hi ha a la carpeta des d'on els llances. Mai des de `/home/teclab`,
    on hi ha l'historial del terminal, les credencials de `gh` i de `claude-compte` i la
    configuració.

    Si el teu marc necessita un altre port, canvia el paràmetre «Port de l'app web del
    projecte» a la fitxa de l'espai → *Settings → Parameters* (l'espai es reconstrueix: desa
    el que tingues obert).

2. A la fitxa de l'espai, prem **App**. S'obri en una pestanya nova, amb l'adreça de dalt.

3. Per a ensenyar-la a altres persones, tria qui la pot obrir al paràmetre **«Qui pot obrir
   l'app web»** (fitxa → *Settings → Parameters*; l'espai es reconstrueix i cal tornar a
   llançar l'app):

    | Opció | Qui la veu |
    |---|---|
    | Només jo (per defecte) | Tu (i les persones administradores, com a tot l'espai). Qualsevol altra persona rep «404 - Application Not Found» |
    | Qualsevol persona amb sessió a Coder | Qui entre a la plataforma amb el seu compte de la UJI |
    | Sense sessió | Qualsevol persona de la xarxa de la UJI (campus o VPN), sense entrar a Coder |

    Després, passa'ls l'adreça. Des de fora de la xarxa de la UJI no s'hi arriba en cap cas.

## Com saber que ha funcionat

- El botó App obri la teua interfície en una pestanya nova, a una adreça que comença per
  `app--`, amb el cadenat del navegador en verd.
- Amb «Només jo», una altra persona amb la mateixa adreça rep «404 - Application Not Found».
- Amb «Qualsevol persona amb sessió a Coder», una companya entra a la plataforma, obri
  l'adreça i veu l'app.

## Si falla

- **El botó obri «connection refused» o una pàgina en blanc**: no hi ha res escoltant al port,
  o l'app escolta a `0.0.0.0` d'un altre port. Comprova `echo $APP_PORT` i la línia de
  llançament.
- **Els enllaços de l'app porten a `/@usuari/...` o a una ruta estranya**: l'app encara té
  configurat un prefix de ruta d'una versió anterior d'esta guia. Lleva'l: ara l'app es
  serveix a l'arrel de la seua adreça.
- **Una altra persona veu «404 - Application Not Found»**: l'app és «Només jo», o l'espai
  està aturat. Canvia el paràmetre (pas 3) i torna a llançar l'app.
- **L'app desapareix al cap d'una estona**: l'espai s'ha aturat per inactivitat. Torna'l a
  engegar i torna a llançar l'app.

!!! warning "Qui la pot veure, ho pot usar tot"
    Si comparteixes l'app, qui l'obri pot fer tot el que l'app permet: formularis, pujades,
    crides a la passarel·la amb la clau del projecte (si l'app les fa). Comparteix-la només
    mentre l'ensenyes, i torna a «Només jo» després.

!!! note "Per a ensenyar, no per a servir"
    Si el projecte necessita una app disponible de manera estable per a usuaris, és un
    desplegament fora del sandbox: vegeu [Preparar el projecte per a la porta 2](preparar-porta-2.md).
