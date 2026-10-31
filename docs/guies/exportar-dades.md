# Exportar dades i codi

L'espai no té còpia de seguretat: el que vulgues conservar fora (abans d'esborrar el
projecte, o per a compartir-lo) l'has d'exportar tu. Tres camins segons què és.

## Codi: a un repositori de GitHub

1. Al terminal, entra a GitHub una vegada per espai:

    ```bash
    gh auth login        # GitHub.com → HTTPS → Login with a web browser
    gh auth setup-git    # perquè git push use la mateixa sessió
    ```

    Mostra un codi i una adreça: obri-la al navegador del teu ordinador i escriu el codi.

2. Inicialitza el repositori al teu projecte (si no ho està) i puja'l:

    ```bash
    cd ~/work/el-meu-projecte
    git init && git add . && git commit -m "primer commit"
    gh repo create el-meu-projecte --private --source . --push
    ```

Abans de pujar, revisa que no hi haja cap credencial: `detect-secrets scan` (eina de la
imatge) llista el que semble una clau.

## Base de dades: un bolcat

```bash
pg_dump --no-owner --format=custom --file ~/work/app.dump
```

Deixa el fitxer a la teua carpeta de treball, des d'on el pots baixar. Per a restaurar-lo en
un altre PostgreSQL 16: `pg_restore --no-owner --dbname <base> app.dump`.

## Fitxers: baixar-los des de VS Code

A l'explorador de fitxers de VS Code (al navegador), botó dret sobre el fitxer o la carpeta
→ **Download**. Per a moltes carpetes, comprimeix abans: `tar czf projecte.tgz el-meu-projecte`.

## Com saber que ha funcionat

- `gh repo view el-meu-projecte --web` obri el repositori amb el teu codi.
- `pg_restore --list app.dump` llista les taules del bolcat.
- El fitxer baixat s'obri al teu ordinador.

## Si falla

- **`gh auth login` no pot obrir el navegador**: és normal dins de l'espai; copia l'adreça i
  el codi al navegador del teu ordinador.
- **`git push` demana usuari i contrasenya**: falta `gh auth setup-git`.
- **`pg_dump` diu `connection refused`**: el sidecar no està en marxa; vegeu
  [La base de dades de l'espai](base-de-dades.md).
- **Download no apareix**: estàs al VS Code local connectat per l'extensió; allà els fitxers
  es copien arrossegant-los a l'explorador del teu ordinador.

!!! warning "Què no exportar"
    Les variables de l'espai (clau del projecte, contrasenya de la base de dades) no
    s'exporten: són de la plataforma i es revoquen amb l'espai. I el que no podia estar a
    l'espai (dades reals) tampoc no pot eixir-ne.
