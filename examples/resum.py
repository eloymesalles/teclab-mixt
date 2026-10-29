"""Exemple de la demo: demana un resum a la passarel·la LLM (LiteLLM, API compatible amb OpenAI).

Llegeix de l'entorn (la posa la plataforma a l'espai; cap valor incrustat aquí):
  LITELLM_BASE_URL  (adreça de la passarel·la; obligatòria)
  LITELLM_KEY       (clau virtual creada a la UI de LiteLLM; obligatòria)
  LITELLM_MODEL     (àlies del catàleg; per defecte chat-default)

Ús:  python resum.py [text a resumir | ruta d'un fitxer .txt]
"""

import os
import sys
import time
from pathlib import Path

from openai import OpenAI

TEXT_PER_DEFECTE = (
    "El Teclab és el laboratori d'intel·ligència artificial de la Universitat Jaume I. "
    "Està avaluant dos entorns d'escriptori gestionats, Coder i JupyterHub, per oferir "
    "espais de treball per projecte des del navegador, amb VS Code i notebooks. Els dos "
    "entorns comparteixen la mateixa imatge, de manera que el codi és portable, i tots "
    "dos accedeixen als models de llenguatge a través d'una passarel·la comuna que "
    "serveix tant models locals, executats amb Ollama, com models comercials."
)


def main() -> int:
    base_url = os.environ.get("LITELLM_BASE_URL", "").strip()
    key = os.environ.get("LITELLM_KEY", "").strip()
    model = os.environ.get("LITELLM_MODEL", "").strip() or "chat-default"
    for nom, valor in (("LITELLM_BASE_URL", base_url), ("LITELLM_KEY", key)):
        if not valor:
            print(
                f"Falta la variable d'entorn {nom}. La posa la plataforma (Coder o JupyterHub) "
                "a l'entorn de l'espai; per a proves locals, vegeu .env.example.",
                file=sys.stderr,
            )
            return 2

    arg = sys.argv[1] if len(sys.argv) > 1 else ""
    if arg and Path(arg).is_file():
        text = Path(arg).read_text(encoding="utf-8")
    else:
        text = arg or TEXT_PER_DEFECTE

    client = OpenAI(base_url=base_url, api_key=key)
    inici = time.perf_counter()
    resposta = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": "Ets un assistent que resumeix textos en català, en dues frases com a màxim."},
            {"role": "user", "content": f"Resumeix aquest text:\n\n{text}"},
        ],
        # Els models de raonament gasten tokens pensant: cal marge
        max_tokens=1500,
        temperature=0.3,
    )
    durada = time.perf_counter() - inici

    contingut = (resposta.choices[0].message.content or "").strip()
    print("── Resum ──")
    print(contingut or "(resposta buida: puja max_tokens o canvia de model)")
    print()
    print(f"model: {resposta.model}  ·  passarel·la: {base_url}")
    if resposta.usage:
        print(f"tokens: {resposta.usage.prompt_tokens} llegits, {resposta.usage.completion_tokens} generats  ·  {durada:.1f} s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
