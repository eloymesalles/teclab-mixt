# La xarxa de l'espai

## Per què no hi ha Internet obert

L'espai és una màquina **sense adreça pública**: des d'Internet no s'hi pot arribar, i quan
l'espai ix cap a fora ho fa per una porta d'eixida compartida (NAT) que només deixa passar
cap a una **llista de dominis permesos**. És una mesura de seguretat de l'entorn: redueix el
risc que un paquet maliciós, un script o un agent amb accés al terminal envie dades a
qualsevol lloc.

El que no és a la llista queda registrat. Durant el període d'observació de la plataforma es
permet igualment; després, es bloquejarà.

## Què sí que es pot fer

Els dominis permesos cobreixen el treball habitual:

| Necessitat | Dominis |
|---|---|
| Paquets de Python (`pip`, `uv`) | `pypi.org`, `files.pythonhosted.org` |
| Paquets de Node (`npm`) | `registry.npmjs.org` |
| Paquets del sistema (`apt`) | `deb.debian.org`, `security.debian.org` |
| GitHub (codi, `gh`, releases) | `github.com`, `api.github.com`, `codeload.github.com`, `objects.githubusercontent.com`, `raw.githubusercontent.com` |
| Imatges de contenidors | `ghcr.io`, `pkg-containers.githubusercontent.com`, `registry-1.docker.io`, `auth.docker.io`, `production.cloudflare.docker.com`, `download.docker.com` |
| Claude Code amb la llicència de la UJI (`claude-compte`) | `api.anthropic.com`, `claude.ai`, `platform.claude.com` |
| Inici de sessió amb Google | `accounts.google.com` |

Els serveis de Google Cloud que usa la plataforma (registre d'imatges, models de Vertex AI)
van per una via privada de Google, no per Internet.

La **passarel·la** i Coder es troben dins de la mateixa xarxa privada: l'espai hi parla pel nom
intern, xifrat amb un certificat de l'autoritat de certificació del Teclab, que l'espai ja
té configurat. No cal cap excepció de verificació (`verify=False`, `curl -k`) enlloc.

## Què no està obert

- Cap connexió entrant a l'espai: ni des d'Internet ni des d'un altre espai. Només una
  persona administradora pot entrar-hi per SSH, per una via identificada de Google.
- Un espai no veu els altres espais: ni la seua màquina ni la seua base de dades.
- Des de l'espai, cap a la plataforma només s'arriba a Coder i a la passarel·la, pels seus
  ports xifrats.
- Les apps web de l'espai (VS Code, JupyterLab, el botó «App») no obrin cap port a la xarxa:
  les serveix Coder per la connexió de l'agent, amb la teua sessió.

## Com demanar un domini

Si el teu projecte necessita un domini que no és a la llista (una API, un repositori de
models, un servei de la UJI), demana-ho a l'administrador/a amb el nom del domini i per a
què. Afegir-lo és un canvi de configuració de la plataforma amb revisió.
