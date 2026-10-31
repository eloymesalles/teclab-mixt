# Cicle de vida d'un espai

## Crear, aturar, engegar, esborrar

Un espai naix quan una persona administradora el crea per al teu projecte. A partir d'ací,
tu l'engegues i l'atures tantes vegades com vulgues; només l'administrador/a pot esborrar-lo
o canviar-ne la mida.

Aturar un espai és apagar la seua màquina. El **disc persistent**, on hi ha la teua carpeta
personal (`/home/teclab`) i la base de dades, es queda intacte i es torna a connectar en
engegar.

| Acció | Màquina | Disc persistent (`/home`, base de dades) | Clau del projecte |
|---|---|---|---|
| Aturar (o 30 minuts d'inactivitat) | s'atura | es queda | es queda |
| Engegar | s'engega; els contenidors es tornen a alçar | es reutilitza | la mateixa |
| Canviar la mida de màquina (administrador/a) | es reinicia amb la mida nova | es queda | la mateixa |
| Canviar accés a models o pressupost (administrador/a) | res | es queda | se'n genera una de nova |
| Esborrar l'espai (administrador/a) | **s'esborra** | **s'esborra**, sense còpia | **es revoca** |

!!! danger "Esborrar és definitiu"
    En esborrar un espai desapareixen la màquina, el disc i la clau. No hi ha paperera ni
    còpia de seguretat del disc. Abans d'esborrar un projecte, exporta el que vulgues
    conservar: [Exportar dades i codi](../guies/exportar-dades.md).

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

Cada espai porta una data prevista de fi del projecte, com a etiqueta d'inventari. No apaga
res per si sola: serveix perquè el Teclab revise els espais que ja no s'usen i acorde amb el
projecte què fer-ne.

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
