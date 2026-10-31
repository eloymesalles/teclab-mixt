# Glossari

Termes fixos d'este manual. Quan un terme té sinònims d'ús corrent, s'indica entre parèntesis
el que **no** usem.

**Espai** (de treball)
: La màquina pròpia d'un projecte al sandbox, amb VS Code, notebooks, terminal, base de dades
  i accés a la passarel·la. (No «workspace», no «instància».)

**Plataforma**
: El conjunt de serveis compartits del sandbox: Coder, la passarel·la i el que els envolta.
  L'opera el Teclab.

**Coder**
: L'eina que gestiona els espais: entrar, engegar, aturar, obrir VS Code. Hi entres amb el
  compte de la UJI.

**Administrador/a**
: Persona del Teclab que crea i esborra espais, canvia mides i pressupostos, i gestiona la
  plataforma.

**Passarel·la**
: El servei que dóna accés als models de llenguatge (LiteLLM). L'espai hi parla amb una
  clau i una API compatible amb OpenAI. (No «proxy», no «LiteLLM» en el text d'usuari.)

**Catàleg**
: La llista d'àlies i models que ofereix la passarel·la.

**Àlies**
: Nom estable del catàleg que apunta a un model (per exemple `chat-default`). Els programes
  demanen àlies, no models.

**Clau del projecte**
: La credencial amb què l'espai crida la passarel·la (`LITELLM_KEY`). Té una llista de
  models i un pressupost. (Al registre de la passarel·la es diu «clau virtual».)

**Pressupost**
: Despesa màxima de la clau del projecte, en dòlars.

**Agent** (de Coder)
: Programa que corre dins de l'espai i el connecta amb Coder: terminal, apps, estat.

**Agent de codi**
: Claude Code, l'assistent que treballa al terminal sobre els teus fitxers (`claude`,
  `claude-compte`). No confondre amb l'agent de Coder.

**Sidecar**
: El contenidor auxiliar de l'espai que executa la base de dades PostgreSQL. Només l'espai hi
  arriba.

**Base de dades de l'espai**
: El PostgreSQL 16 amb pgvector del sidecar; base `app`, usuari `app`.

**Disc persistent**
: El disc que conserva `/home/teclab` i la base de dades entre aturades.

**Imatge**
: El contingut inicial de l'espai (eines i versions), `teclab-mixt`. Cada arrancada parteix
  de la imatge més el disc persistent.

**Plantilla**
: La definició de com es crea un espai (màquina, disc, variables, apps). La gestiona
  l'administrador/a.

**App** (botó)
: Enllaç de la fitxa de l'espai a Coder que obri una interfície web que corre dins de l'espai
  (VS Code, JupyterLab, o l'app del projecte).

**CA del Teclab**
: L'autoritat de certificació privada que signa els certificats interns de la plataforma.
  L'espai hi confia automàticament.

**Porta**
: Punt de control del procediment del Teclab que un projecte ha de passar per avançar
  d'etapa (del sandbox cap a un entorn real).

**Dades sintètiques**
: Dades generades artificialment, sense cap persona ni fet real darrere. Les úniques que es
  poden usar a l'espai, juntament amb les anonimitzades.
