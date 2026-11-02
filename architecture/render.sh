#!/usr/bin/env bash
# Regenerates every diagram in this folder from its source:
#
#   *.py   Python "diagrams" (Graphviz)  ->  *.png
#   *.mmd  Mermaid                       ->  *.svg
#
# Needs Python 3.11+, Graphviz (dot) and Node.js 22.13+ (npx). The Python
# packages go into architecture/.venv from the hash-pinned requirements.txt;
# the Mermaid CLI runs through npx at a pinned version (it downloads a headless
# Chrome on first use).
#
# Usage: architecture/render.sh [name ...]   e.g. render.sh kubernetes gitops
set -euo pipefail

MERMAID_CLI_VERSION=12.0.0

cd "$(dirname "$0")"

need() {
  command -v "$1" >/dev/null || {
    echo "render.sh: $1 is required ($2)" >&2
    exit 1
  }
}

render_python() {
  need dot "Graphviz, e.g. brew install graphviz"
  need python3 "Python 3.11 or newer"
  # Rebuild the virtualenv whenever requirements.txt changes.
  if [[ ! -x .venv/bin/python ]] || ! cmp -s requirements.txt .venv/requirements.txt; then
    rm -rf .venv
    python3 -m venv .venv
    .venv/bin/python -m pip install --quiet --disable-pip-version-check \
      --require-hashes -r requirements.txt
    cp requirements.txt .venv/requirements.txt
  fi
  echo "rendering $1.py -> $1.png"
  .venv/bin/python -I "$1.py"
}

render_mermaid() {
  need npx "Node.js 22.13 or newer"
  echo "rendering $1.mmd -> $1.svg"
  # A white background keeps the diagram readable in dark mode too.
  npx --yes "@mermaid-js/mermaid-cli@${MERMAID_CLI_VERSION}" --quiet \
    --input "$1.mmd" --output "$1.svg" --backgroundColor white
  # End with a newline, as the end-of-file pre-commit hook expects.
  if [[ -n $(tail -c 1 "$1.svg") ]]; then
    echo >>"$1.svg"
  fi
}

if [[ $# -eq 0 ]]; then
  for source in *.py *.mmd; do
    set -- "$@" "${source%.*}"
  done
fi

for name in "$@"; do
  if [[ -f $name.py ]]; then
    render_python "$name"
  elif [[ -f $name.mmd ]]; then
    render_mermaid "$name"
  else
    echo "render.sh: no $name.py or $name.mmd here" >&2
    exit 1
  fi
done
