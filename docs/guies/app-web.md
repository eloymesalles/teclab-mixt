# Mostrar una app web

Si el teu projecte té una interfície web (Streamlit, Gradio, FastAPI, Flask…), l'espai pot
mostrar-la amb un botó **App** a la fitxa de Coder. No és una manera de servir-la: l'app
només existeix mentre l'espai és engegat i tu l'has llançada.

!!! note "Només tu la pots obrir"
    Les apps de l'espai s'obrin sota l'adreça de la plataforma, i Coder no permet compartir-les
    de manera segura amb altres persones (ni tan sols amb l'administrador/a): qualsevol altra
    persona rep «404 - Application Not Found». Per a ensenyar-la, comparteix la pantalla. La
    compartició arribarà amb les apps per subdomini (una adreça pròpia per a cada app), en
    preparació.

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

1. El botó **App** ja hi és, i apunta al port `8080` (variable `APP_PORT`). Si el teu marc
   necessita un altre port, canvia el paràmetre «Port de l'app web del projecte» a la fitxa
   de l'espai → *Settings → Parameters*. És l'únic paràmetre que pots editar; en desar,
   l'espai es reconstrueix (desa el que tingues obert).
2. Llança l'app escoltant al port que diu `APP_PORT`.
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
- Una altra persona amb la mateixa adreça rep «404 - Application Not Found»: és el
  comportament esperat.

## Si falla

- **El botó obri «connection refused»**: no hi ha res escoltant al port, o l'app escolta a
  `0.0.0.0` d'un altre port. Comprova `echo $APP_PORT` i la línia de llançament.
- **La pàgina carrega però sense estils, o els enllaços donen 404**: l'app no serveix sota el
  prefix de ruta. Configura el paràmetre del teu marc (llista de dalt).
- **Una altra persona veu «404 - Application Not Found»**: només tu pots obrir l'app (vegeu
  l'avís de l'inici).
- **L'app desapareix al cap d'una estona**: l'espai s'ha aturat per inactivitat. Torna'l a
  engegar i torna a llançar l'app.

!!! note "Per a ensenyar, no per a servir"
    Si el projecte necessita una app disponible de manera estable per a usuaris, és un
    desplegament fora del sandbox: vegeu [Preparar el projecte per a la porta 2](preparar-porta-2.md).
