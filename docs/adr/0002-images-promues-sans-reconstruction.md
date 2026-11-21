# ADR 0002 · Les images sont construites une fois sur `dev`, puis promues

Date : 20 novembre 2026 · Statut : proposé

## Contexte

R44 disait qu'une image n'est construite qu'au merge `staging` → `main`. Ce qui est testé en recette (`staging`) n'est donc pas l'image qui part en production : on la reconstruit, avec le risque que le résultat diffère (image de base qui a bougé, dépendance résolue autrement). Traintracks suit déjà une autre logique, éprouvée : une image par contenu, construite sur `dev`, puis re-étiquetée à chaque marche.

## Décision

- Une image est construite **une fois**, à la fusion dans `dev`, seulement pour les services dont les sources ont changé (empreinte par service).
- `staging`, `main` et les versions `vX.Y.Z` **re-étiquettent** cette image (tags `staging`, `prod`, `vX.Y.Z`). La promotion échoue si l'image n'existe pas, au lieu de reconstruire.
- Un **manifeste** (image et digest de chaque service) est publié sur GHCR et joint à la release GitHub : il dit exactement ce qui est en production (R32).
- **Jamais `latest`**, y compris pour un outil de mise à jour automatique : il suit le tag `prod`.
- Le tout est fourni par `images-dev.yml`, `promouvoir-images.yml`, `nettoyer-images-non-promues.yml` et `scripts/images.sh`, appelés par chaque projet (voir [mise en œuvre](../mise-en-oeuvre.md)).
- `publier-image.yml` reste pour les projets qui l'utilisent, sans être la référence.

## Conséquences

- Ce qui est validé en recette est, au bit près, ce qui part en production.
- Plus d'images construites qu'avant (une par fusion dans `dev`), compensé par la reconstruction partielle et le nettoyage de `images.sh`. Voir la limite de stockage dans la mise en œuvre.
- Un hotfix passe lui aussi par `dev` (R45), sinon la promotion échoue : c'est voulu.
- `nettoyer-images.yml` ne doit pas être utilisé avec ce modèle (il ignore les tags d'étape).
- Traintracks n'a plus besoin de son propre `images.sh` ni de ses workflows : il appellera les workflows partagés. Ce sera une PR sur ce projet.
- **Point ouvert** : R23 prévoit release-please pour proposer la version et le changelog. Ici la version est posée à la main (`scripts/poser-version.sh`) et les notes de release viennent de `--generate-notes`. Les deux se combinent (release-please poserait le tag), mais release-please crée lui-même la release GitHub : il faudra alors que `promouvoir-images.yml` y joigne le manifeste au lieu de la créer. À trancher dans une PR séparée.
