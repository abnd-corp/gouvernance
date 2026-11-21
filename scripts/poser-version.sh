#!/usr/bin/env bash
# Pose une version : le tag vX.Y.Z sur main (ce qui est en production), puis le pousse.
# La CI (promouvoir-images.yml) pose alors la version sur les images de la prod et crée la release GitHub avec le manifeste.
# À lancer depuis la racine du projet : scripts/poser-version.sh 1.2.3 (ou make release V=1.2.3).
set -euo pipefail
V=${1:-}
[[ "$V" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Usage : poser-version.sh X.Y.Z"; exit 1; }
git fetch -q --tags origin main
if git rev-parse -q --verify "refs/tags/v$V" >/dev/null; then
  echo "La version v$V existe déjà."
  exit 1
fi
commit=$(git rev-parse origin/main)
echo "Version v$V sur main : $(git log -1 --format='%h %s' "$commit")"
git tag -a "v$V" "$commit" -m "Version $V"
git push origin "v$V"
echo "Suivi : gh run watch \$(gh run list -w Promotion -L 1 --json databaseId -q '.[0].databaseId')"
