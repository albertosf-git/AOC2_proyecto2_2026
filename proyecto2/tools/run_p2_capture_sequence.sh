#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUNDLE_DIR="$PROJECT_DIR/gtkwave_bundle"
WAVES_DIR="$BUNDLE_DIR/waves"
GTKW_DIR="$BUNDLE_DIR/gtkw"
MANIFEST="$BUNDLE_DIR/capture_manifest.tsv"

if [[ ! -f "$MANIFEST" ]]; then
  echo "Falta el manifest del bundle. Ejecuta primero:"
  echo "  $PROJECT_DIR/tools/generate_p2_capture_bundle.sh"
  exit 1
fi

if ! command -v gtkwave >/dev/null 2>&1; then
  echo "gtkwave no esta disponible en PATH."
  exit 1
fi

if [[ -z "${DISPLAY:-}" ]]; then
  echo "DISPLAY no esta definido. Este script necesita entorno grafico."
  exit 1
fi

while IFS=$'\t' read -r cap slug _inst _data _stop _timestart description; do
  wave="$WAVES_DIR/capture_${cap}_${slug}.ghw"
  gtkw="$GTKW_DIR/capture_${cap}_${slug}.gtkw"

  if [[ ! -f "$wave" || ! -f "$gtkw" ]]; then
    echo "Faltan artefactos para la captura $cap ($slug)."
    echo "Regenera el bundle con:"
    echo "  $PROJECT_DIR/tools/generate_p2_capture_bundle.sh"
    exit 1
  fi

  echo
  echo "============================================================"
  echo "Captura $cap/11"
  echo "$description"
  echo "Wave: $wave"
  echo "View: $gtkw"
  echo "============================================================"
  gtkwave "$wave" "$gtkw"
  if [[ "$cap" != "11" ]]; then
    printf 'Pulsa Enter para abrir la siguiente captura...'
    read -r _ </dev/tty
  fi
done < <(tail -n +2 "$MANIFEST")
