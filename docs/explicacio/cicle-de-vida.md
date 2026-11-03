# Cicle de vida d'un espai

## Crear, aturar, engegar, esborrar

Un espai naix quan una persona administradora el crea per al teu projecte (l'espai porta el
nom del projecte), i en eixe moment en fixa la mida de màquina i el disc. A partir d'ací, tu
l'engegues i l'atures tantes vegades com vulgues; només l'administrador/a pot esborrar-lo.

Aturar un espai és apagar la seua màquina. El **disc persistent**, on hi ha la teua carpeta
personal (`/home/teclab`) i la base de dades, es queda intacte i es torna a connectar en
engegar.

| Acció | Màquina | Disc persistent (`/home`, base de dades) | Clau del projecte |
|---|---|---|---|
| Aturar (o 30 minuts d'inactivitat) | s'atura | es queda | es queda |
| Engegar | s'engega; els contenidors es tornen a alçar | es reutilitza | la mateixa |
| Canviar models o pressupost de la clau (administrador/a) | res | es queda | la mateixa, amb els valors nous |
| Canviar la mida de màquina (administrador/a, amb l'espai aturat) | s'engega amb la mida nova | es queda | la mateixa |
| Engrandir el disc (administrador/a) i aturar i engegar | es reinicia | creix | la mateixa |
| Esborrar l'espai (administrador/a) | **s'esborra** | **s'esborra**, sense còpia | **es revoca** |

!!! danger "Esborrar és definitiu"
    En esborrar un espai desapareixen la màquina, el disc i la clau. No hi ha paperera ni
    còpia de seguretat del disc. Abans d'esborrar un projecte, exporta el que vulgues
    conservar: [Exportar dades i codi](../guies/exportar-dades.md).

## Els paràmetres de l'espai

A la fitxa de l'espai, *Settings → Parameters* mostra la mida de màquina i el disc amb què
es va crear l'espai, i el port de l'app web. Màquina i disc no es canvien des d'ací: si el
projecte necessita més màquina, més disc, altres models o més pressupost, demana-ho a
l'administrador/a, que ho canvia sense recrear l'espai (la màquina, amb l'espai aturat; el
disc només pot créixer). La fitxa continuarà mostrant la mida inicial; els indicadors de
CPU, RAM i disc mostren la real.

L'únic paràmetre que pots editar tu és el **port de l'app web**
([Mostrar una app web](../guies/app-web.md)).

## Què es conserva i què no

- **Es conserva** entre aturades: tot el que hi ha a `/home/teclab` (el teu treball, la
  configuració de VS Code, les credencials de `gh` i de `claude-compte`) i la base de dades.
- **No es conserva**: el que hages instal·lat fora de la teua carpeta (paquets del sistema,
  programes a `/usr`). L'espai torna a la imatge en cada arrancada. Els paquets de Python
  instal·lats amb `pip install --user` o en un entorn virtual dins de `/home/teclab` sí que es
  queden.
- Els programes que tenies en marxa (un notebook executant-se, una app web) s'aturen amb
  l'espai: en engegar-lo cal tornar-los a llançar.

## Aturada automàtica

Un espai s'atura sol als **30 minuts** sense activitat. És el comportament esperat: una
màquina aturada no costa diners de càlcul. Si tens una tasca llarga, mantín oberta una
sessió activa o demana a l'administrador/a com procedir.

## Actualitzacions de la imatge

De tant en tant el Teclab publica una versió nova de la imatge de l'espai (eines noves,
versions actualitzades). L'administrador/a la posa a la plantilla; el teu espai l'estrena
quan s'actualitza i es torna a engegar. El teu disc persistent no es toca.

## Caducitat

Cada projecte té una data prevista de fi a l'inventari del Teclab. No apaga res per si sola:
serveix perquè el Teclab revise els espais que ja no s'usen i acorde amb el projecte què
fer-ne.

## Les portes

El sandbox és la primera etapa d'un projecte: ací s'experimenta amb dades sintètiques o
anonimitzades i s'ensenya el resultat. Quan el projecte vol anar més enllà (dades reals,
usuaris de veritat, un servei que funcione sol), ha de passar per les **portes** del
procediment del Teclab, que fixen què cal tindre a punt en cada etapa.

Per a la segona porta, la que porta el projecte fora de l'espai, el que es demana és que el
codi puga arrancar sol en un contenidor, amb la seua configuració fora del codi:
[Preparar el projecte per a la porta 2](../guies/preparar-porta-2.md).

!!! info "Pendent"
    La llista de comprovació de les portes es publicarà en este manual quan el Teclab la
    tanque. Mentrestant, demana-la a l'administrador/a.
