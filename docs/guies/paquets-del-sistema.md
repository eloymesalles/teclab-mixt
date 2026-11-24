# Instal·lar paquets del sistema

L'usuari de l'espai (`teclab`) pot fer `sudo` sense contrasenya: instal·lar paquets de
Debian amb `apt`, posar un programa a `/usr/local` o executar qualsevol ordre com a root
dins del teu espai. No afecta cap altre espai ni la plataforma: el contenidor de l'espai
corre sense privilegis sobre la màquina.

## Instal·lar un paquet i conservar-lo

```bash
teclab-paquets afegir htop ffmpeg
```

Instal·la els paquets (amb `apt-get`) i els apunta a `~/.teclab/paquets`, que és al disc
persistent. Quan la imatge de l'espai s'actualitze i el sistema torne al de la imatge, l'espai
els reinstal·larà sol en arrancar (en segon pla; el registre queda a `~/.teclab/paquets.log`).

```bash
teclab-paquets llista              # què hi ha apuntat
teclab-paquets treure htop         # el lleva de la llista i el desinstal·la
teclab-paquets restaurar           # reinstal·la tota la llista ara mateix
```

Els noms són els dels paquets de Debian 12 (`apt search <paraula>` per a buscar-ne).
La llista és un fitxer de text amb un nom per línia: també la pots editar a mà.

## Instal·lar sense apuntar-ho

`sudo apt-get install <paquet>` o `sudo` amb qualsevol altra ordre funciona igual, però el
que faces així **es perd quan la imatge s'actualitza**: entre aturades normals es queda. Per a
proves ràpides va bé; per al que el projecte necessita de veritat, `teclab-paquets afegir`.

## Què es conserva i què no

| On | Aturar i engegar | Actualització de la imatge |
|---|---|---|
| `/home/teclab` (treball, `pip install --user`, entorns virtuals, la llista de paquets) | es queda | es queda |
| Paquets de `teclab-paquets` | es queden | es reinstal·len sols |
| Resta del sistema (`sudo apt-get install` sense apuntar, `/usr/local`, `/etc`) | es queda | **torna a la imatge** |

Més detall: [Cicle de vida d'un espai](../explicacio/cicle-de-vida.md).

## Límits

- Els repositoris d'`apt` que l'espai pot consultar són els de Debian (`deb.debian.org`,
  `security.debian.org`), per la [llista de dominis permesos](../explicacio/xarxa-de-l-espai.md).
  Un repositori de tercers no s'hi arribarà: demana el domini a l'administrador/a.
- El que instal·les fora de `/home/teclab` ocupa el disc del sistema de la màquina (20 GB,
  compartits amb la imatge), no el disc persistent: paquets molt grans poden omplir-lo.
- Amb `sudo` pots espatllar el teu propi espai (esborrar una eina de la imatge, trencar
  Python del sistema). Si passa, demana a l'administrador/a que l'actualitze: el sistema torna
  al de la imatge i el teu `/home/teclab` i la base de dades no es toquen.
- Docker no hi és: l'espai és un contenidor i no en pot crear d'altres.
