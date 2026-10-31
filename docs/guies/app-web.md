# Mostrar una app web

Si el teu projecte té una interfície web (Streamlit, Gradio, FastAPI, Flask…), l'espai pot
mostrar-la amb un botó **App** a la fitxa de Coder. És una manera d'**ensenyar** el projecte
a altres persones de la UJI, no de servir-lo: l'app només existeix mentre l'espai és engegat i
tu l'has llançada.

## Com funciona

Coder reenvia el botó cap a un port de l'espai, sota una ruta pròpia. El contracte que ha
de complir la teua app:

1. Escoltar a `127.0.0.1` al port que diu la variable `APP_PORT`.
2. Servir-se sota el prefix de ruta `/@<usuari>/<espai>/apps/app/` (l'espai el pot calcular
   amb `CODER_WORKSPACE_OWNER_NAME` i `CODER_WORKSPACE_NAME`).

La majoria de marcs tenen un paràmetre per al prefix: Streamlit `--server.baseUrlPath`,
Gradio `root_path`, FastAPI `--root-path`, Flask `APPLICATION_ROOT`, Django
`FORCE_SCRIPT_NAME`, Next.js `basePath`, Vite `base`.

## Passos

1. Demana a l'administrador/a que active el botó per al teu espai: cal indicar el **port**
   (per exemple `8501`) i **qui el pot obrir**: només tu (`owner`), qualsevol persona amb
   sessió a Coder (`authenticated`) o sense sessió però només des de la xarxa de la UJI
   (`public`). El màxim permés el fixa la plantilla.
2. Quan estiga actiu, a l'espai hi haurà la variable `APP_PORT`. Llança l'app escoltant-hi.
   Exemple amb Streamlit:

    ```bash
    RUTA="/@${CODER_WORKSPACE_OWNER_NAME}/${CODER_WORKSPACE_NAME}/apps/app"
    streamlit run app.py --server.address 127.0.0.1 --server.port "$APP_PORT" \
      --server.baseUrlPath "$RUTA"
    ```

3. A la fitxa de l'espai, prem **App**.

## Com saber que ha funcionat

- El botó App obri la teua interfície en una pestanya nova, amb una adreça que comença per
  la de la plataforma i conté `/apps/app/`.
- Una altra persona amb el nivell de compartició adequat la veu des del seu navegador, dins
  de la xarxa de la UJI.

## Si falla

- **No hi ha botó App**: l'espai no té port configurat. Pas 1.
- **El botó obri «connection refused»**: no hi ha res escoltant al port, o l'app escolta a
  `0.0.0.0` d'un altre port. Comprova `echo $APP_PORT` i la línia de llançament.
- **La pàgina carrega però sense estils, o els enllaços donen 404**: l'app no serveix sota el
  prefix de ruta. Configura el paràmetre del teu marc (llista de dalt).
- **Algú de fora no la veu**: el nivell de compartició és `owner`, o la persona és fora de la
  xarxa de la UJI (també amb `public`).
- **L'app desapareix al cap d'una estona**: l'espai s'ha aturat per inactivitat. Torna'l a
  engegar i torna a llançar l'app.

!!! note "Per a ensenyar, no per a servir"
    Si el projecte necessita una app disponible de manera estable per a usuaris, és un
    desplegament fora del sandbox: vegeu [Preparar el projecte per a la porta 2](preparar-porta-2.md).
