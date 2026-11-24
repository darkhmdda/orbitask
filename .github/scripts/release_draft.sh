#!/usr/bin/env bash
# Gestiona el borrador de release que comparten los workflows de Android,
# Linux y Windows. Las tres plataformas de una misma etiqueta acaban en una
# sola release.
#
#   release_draft.sh check   TAG
#       Falla si ya hay una release PUBLICADA con esa etiqueta. Un borrador
#       existente no es un error: la plataforma se añadirá a él.
#
#   release_draft.sh publish TAG PRERELEASE ARCHIVO...
#       Si no hay release, crea un borrador con los archivos. Si hay un
#       borrador, le añade los archivos (sustituye los que tengan el mismo
#       nombre). Si la release ya está publicada, falla sin tocar nada.
#
# Necesita GH_TOKEN y GITHUB_REPOSITORY. Las llamadas a "publish" de una
# misma etiqueta deben ir en serie (concurrency en el job), o dos workflows
# podrían crear dos borradores a la vez.
set -euo pipefail

mode="${1:?Falta el modo: check o publish}"
tag="${2:?Falta la etiqueta}"
repo="${GITHUB_REPOSITORY:?Falta GITHUB_REPOSITORY}"

# Estado de la release con esa etiqueta: "none", "draft" o "published".
# Se busca en la lista de releases porque los borradores todavía no tienen
# etiqueta git y no aparecen en /releases/tags/TAG.
release_state() {
  local states
  states="$(gh api "repos/$repo/releases" --paginate \
    --jq ".[] | select(.tag_name == \"$tag\") | if .draft then \"draft\" else \"published\" end")"
  if [ -z "$states" ]; then
    echo none
  elif [ "$(echo "$states" | wc -l)" -gt 1 ]; then
    echo "::error::Hay varias releases con la etiqueta $tag. Borra los borradores sobrantes en Releases." >&2
    exit 1
  else
    echo "$states"
  fi
}

state="$(release_state)"

if [ "$state" = "published" ]; then
  echo "::error::La release $tag ya está publicada. Usa otra etiqueta; los workflows nunca modifican una release publicada."
  exit 1
fi

case "$mode" in
  check)
    if [ "$state" = "draft" ]; then
      echo "Ya hay un borrador de $tag; esta plataforma se añadirá a él."
    else
      echo "No hay release $tag; se creará un borrador."
    fi
    ;;
  publish)
    prerelease="${3:?Falta PRERELEASE (true o false)}"
    shift 3
    if [ "$#" -eq 0 ]; then
      echo "::error::No hay archivos que publicar."
      exit 1
    fi
    if [ "$state" = "draft" ]; then
      gh release upload "$tag" "$@" --repo "$repo" --clobber
      echo "Archivos añadidos al borrador $tag."
    else
      flags=(--draft --target "$GITHUB_SHA" --title "Orbitask $tag"
        --notes "Borrador creado por los workflows de release desde \`$GITHUB_REF_NAME\` ($GITHUB_SHA). Sustituye este texto por las notas de la versión.")
      if [ "$prerelease" = "true" ]; then
        flags+=(--prerelease)
      fi
      gh release create "$tag" --repo "$repo" "${flags[@]}" "$@"
      echo "Borrador $tag creado."
    fi
    ;;
  *)
    echo "::error::Modo desconocido: $mode"
    exit 1
    ;;
esac
