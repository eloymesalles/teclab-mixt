# El teu primer espai

En vint minuts: entrar, engegar l'espai que t'han creat, obrir VS Code, demanar un resum a un
model, consultar la base de dades i aturar l'espai. No cal instal·lar res.

## Abans de començar

- Una persona administradora del Teclab t'ha creat l'espai i t'ha dit l'adreça de la
  plataforma.
- Estàs a la xarxa de la UJI (campus o VPN). Des de fora, l'adreça no respon.
- Tens el teu compte de la UJI a mà.

!!! note "Situació provisional"
    Fins que la UJI no publique els noms definitius, pot caldre una línia al fitxer `hosts`
    del teu ordinador i acceptar un avís del navegador sobre el certificat. L'administrador/a
    t'ho haurà indicat; si no, pregunta-li-ho.

## 1. Entra

1. Obri l'adreça de la plataforma al navegador.
2. Prem **Entra amb el compte de la UJI** i tria el teu compte.
3. Apareix la pàgina **Workspaces** amb el teu espai.

Si en lloc de l'espai veus un missatge que no tens accés, el teu usuari encara no està creat:
avisa l'administrador/a.

## 2. Engega l'espai

1. Prem el nom de l'espai per a obrir la seua fitxa.
2. Si està aturat, prem **Start**.
3. Espera que l'indicador de l'agent passe a **Connected** i que **Postgres** diga «sana». La
   primera vegada pot trigar uns minuts: la màquina es crea i baixa la imatge.

## 3. Obri VS Code

1. A la fitxa, prem **VS Code**. S'obri en una pestanya nova, a la carpeta `work`.
2. Obri un terminal: *Terminal → New Terminal*. Ja ets a `/home/teclab/work`.

## 4. Demana un resum a un model

Al terminal:

```bash
python examples/resum.py
```

El programa envia un text a la passarel·la amb l'àlies `chat-default` i mostra el resum, el
model que l'ha fet, els tokens i el temps:

```text
── Resum ──
(dos frases de resum)

model: gemini-2.5-flash  ·  passarel·la: https://…/v1
tokens: 180 llegits, 45 generats  ·  1.4 s
```

Prova amb el teu propi text: `python examples/resum.py "El text que vulgues resumir"`.

## 5. Consulta la base de dades

Cada espai té la seua base de dades PostgreSQL. Comprova que respon i carrega-hi les dades
d'exemple (sintètiques):

```bash
psql -c 'select 1'
python examples/dades.py --carrega
DATA_SOURCE=postgres python examples/dades.py
```

L'última ordre llista les sol·licituds llegides de la base de dades.

## 6. Atura l'espai

A la fitxa de l'espai a Coder, prem **Stop**. La màquina s'apaga; el teu treball a `work/` i
la base de dades es conserven. Si te n'oblides, l'espai s'atura sol als 30 minuts sense
activitat.

## Com saber que ha funcionat

- `resum.py` ha mostrat un resum i una línia `model: …`.
- `psql -c 'select 1'` ha tornat `1`.
- `DATA_SOURCE=postgres python examples/dades.py` ha mostrat `font: postgres` i una llista de
  sol·licituds.
- L'espai apareix com a **Stopped** a Coder.

## Si falla

- **L'adreça no carrega**: no ets a la xarxa de la UJI, o falta la línia al fitxer `hosts`
  (situació provisional).
- **«Entra amb el compte de la UJI» et rebutja**: el teu usuari no existeix encara a la
  plataforma. Avisa l'administrador/a.
- **L'agent es queda en «taking longer than expected»** la primera vegada: pot ser que
  l'espai s'haja creat abans de la teua primera entrada. Entrar una vegada sol
  desbloquejar-ho; si no, atura i engega l'espai.
- **`Falta la variable d'entorn LITELLM_KEY`**: l'espai no té accés a models. Demana-ho.
- **Error 401/403 en `resum.py`**: la clau no té accés a `chat-default` o el pressupost s'ha
  esgotat. Avisa l'administrador/a.
- **`psql: connection refused`**: la base de dades encara arranca. Espera un minut i repeteix.

## Següents passos

- [Notebooks](../guies/notebooks.md) per a treballar amb JupyterLab.
- [L'agent de codi](../guies/agent-de-codi.md) per a tindre Claude Code al terminal.
- [La passarel·la i el catàleg](../explicacio/passarel-la-i-catalog.md) per a entendre què
  acabes de fer.
