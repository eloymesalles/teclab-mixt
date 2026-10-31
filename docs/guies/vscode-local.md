# Connectar el teu VS Code

El VS Code del navegador que obri Coder és suficient per a la majoria de tasques. Si
prefereixes el VS Code instal·lat al teu ordinador (extensions pròpies, tecles, temes), pots
connectar-lo a l'espai: el codi continua a l'espai; el teu VS Code només és la finestra.

## Requisits

- Estar a la xarxa de la UJI (campus o VPN): la plataforma només accepta connexions des d'allà.
- VS Code instal·lat al teu ordinador.
- L'espai engegat (o Coder l'engegarà en connectar).

## Passos

1. Al VS Code del teu ordinador, instal·la l'extensió **Coder** (editor: Coder; l'extensió es
   diu `coder.coder-remote`).
2. Obri la barra lateral de Coder (icona nova a l'esquerra) i prem **Login**.
3. Escriu l'adreça de la plataforma (la que uses al navegador) i accepta obrir el navegador.
4. Al navegador, entra amb el compte de la UJI si cal i copia el **token de sessió** que
   mostra la pàgina.
5. Torna a VS Code i enganxa el token.
6. A la llista d'espais, tria el teu i prem **Open workspace**. S'obri una finestra nova,
   connectada a l'espai, amb la carpeta `/home/teclab/work`.

Alternativa des de la fitxa de l'espai a Coder: el botó **VS Code Desktop** fa els mateixos
passos i obri el VS Code local directament.

## Com saber que ha funcionat

- A la cantonada inferior esquerra de VS Code posa el nom de l'espai (connexió remota).
- *Terminal → New Terminal* obri un terminal **dins de l'espai**: `hostname` torna el nom de
  l'espai, i `python examples/resum.py` funciona igual que al VS Code del navegador.

## Si falla

- **«Login» no obri res o el token no val**: comprova que l'adreça és exactament la de la
  plataforma i que ets a la xarxa de la UJI. Un token caducat es renova repetint el pas 2.
- **L'espai no apareix a la llista**: l'espai és d'un altre usuari o encara no te l'han creat.
  Demana-ho a l'administrador/a.
- **La connexió cau al cap d'una estona**: l'espai s'ha aturat per inactivitat (30 minuts
  sense activitat al terminal ni a les apps). Torna'l a engegar des de Coder.
- **El VS Code local demana instal·lar un servidor remot** la primera vegada: és normal;
  s'instal·la dins de l'espai, a la teua carpeta.

!!! info "Assistents d'IA al VS Code local"
    Les extensions d'assistència amb IA del teu VS Code (autocompletat, xat) envien codi a
    serveis externs des del teu ordinador, fora del perímetre de l'espai. Quines estan
    autoritzades és una decisió del Teclab pendent de publicar en este manual. Mentrestant,
    per a treballar amb IA sobre el codi de l'espai usa [l'agent de codi](agent-de-codi.md)
    de l'espai.
