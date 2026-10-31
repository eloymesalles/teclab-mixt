# Notebooks

L'espai porta JupyterLab. S'obri des de la fitxa de l'espai a Coder, amb la teua sessió, i
treballa sobre la mateixa carpeta que VS Code: `/home/teclab/work`.

## Obrir JupyterLab

1. A Coder, obri la fitxa del teu espai (engega'l si cal).
2. Prem el botó **JupyterLab**. S'obri en una pestanya nova.
3. A l'explorador de fitxers de l'esquerra veuràs `work/`, i dins, `examples/`.

## Executar el notebook d'exemple

1. Obri `examples/resum.ipynb`.
2. Executa les cel·les en ordre (`Maj+Intro`). El notebook demana un resum a la passarel·la
   amb l'àlies `chat-default` i mostra la llista de models que pot cridar la teua clau.
3. Guarda'l amb un altre nom dins de `work/` si vols modificar-lo: la carpeta `examples/` és la
   teua còpia i la pots canviar, però així conserves l'original.

## Crear un notebook nou

1. *File → New → Notebook*, nucli **Python 3**.
2. Les variables de la passarel·la i de la base de dades ja són a l'entorn del nucli:

    ```python
    import os
    from openai import OpenAI

    client = OpenAI(base_url=os.environ["LITELLM_BASE_URL"], api_key=os.environ["LITELLM_KEY"])
    resposta = client.chat.completions.create(
        model=os.environ.get("LITELLM_MODEL", "chat-default"),
        messages=[{"role": "user", "content": "Digues hola en valencià."}],
    )
    print(resposta.choices[0].message.content)
    ```

3. Per a instal·lar un paquet des del notebook: `%pip install --user nom-del-paquet`. Queda
   al teu disc persistent.

## Com saber que ha funcionat

- `resum.ipynb` mostra un resum de dues frases i, a sota, el model i els tokens usats.
- Un notebook nou apareix a `work/` també des de VS Code, i al revés.

## Si falla

- **El botó JupyterLab dóna error de connexió**: JupyterLab encara està arrancant (uns segons
  després d'engegar l'espai). Espera i torna a prémer.
- **`KeyError: 'LITELLM_KEY'`**: l'espai no té clau de projecte (accés a models «cap»).
  Demana a l'administrador/a que l'active.
- **Error 401 o 403 de la passarel·la**: la clau no té accés a eixe model, o el pressupost
  s'ha esgotat. Comprova els models amb `GET /models`
  (vegeu [Àlies i models](../referencia/alies-models.md)).
- **El nucli es reinicia o es queda sense memòria**: la mida de l'espai és petita per al que
  fas. Tanca altres notebooks (*Kernel → Shut Down All Kernels*) o demana una mida més gran.
- **Has perdut un notebook en aturar l'espai**: només es conserva el que és a
  `/home/teclab`. Els fitxers fora d'eixa carpeta desapareixen en cada arrancada.
