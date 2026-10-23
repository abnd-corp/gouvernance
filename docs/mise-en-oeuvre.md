# Mise en œuvre de la charte

La charte dit ce qui est la règle. Ce document dit comment elle s'applique, avec le plan GitHub gratuit.

## Ce que le plan gratuit permet, et ne permet pas

| Besoin | Disponible | Comment |
|---|---|---|
| Règles de branche sur un dépôt public (ruleset) | oui | Un ruleset par dépôt |
| Règles imposées à toute l'organisation (rulesets d'orga) | non, offre payante | On copie le même ruleset dans chaque dépôt (voir ci-dessous) |
| Workflow partagé appelé par tous les dépôts | oui, si ce dépôt est public | `uses: abnd-corp/gouvernance/.github/workflows/controle-pr.yml@<empreinte>` |
| Fichiers par défaut (`CONTRIBUTING.md`, modèles) hérités automatiquement | seulement via un dépôt nommé `.github` | Pas en place : chaque projet renvoie vers ce dépôt |

Conséquence : la gouvernance **se copie** dans chaque projet au lieu de s'imposer d'en haut. C'est la discipline (R33, revue de PR) et le contrôle de PR partagé qui font le reste. Si on prend un jour l'offre payante, on bascule sur des rulesets d'orga sans changer la charte.

## Rattacher un projet

1. **Contrôle de PR (R5, R16).** Ajouter `.github/workflows/controle-pr.yml` :

   ```yaml
   name: Contrôle des PR
   on:
     pull_request:
       types: [opened, edited, synchronize, reopened]
   permissions:
     contents: read
     pull-requests: read
   jobs:
     controle:
       uses: abnd-corp/gouvernance/.github/workflows/controle-pr.yml@main
   ```

   La charte demande de figer un workflow externe sur une empreinte exacte (R24) : remplacer `main` par l'empreinte du commit de ce dépôt dès qu'une version est validée. Dépendabot / Renovate la met ensuite à jour.

2. **Ruleset de `main`.** Dépôt → Settings → Rules → Rulesets. Mêmes règles que celles de ce dépôt : suppression et force-push interdits, commits signés, PR obligatoire avec 1 review, merge en squash seul, et le check « Contrôle des PR » obligatoire une fois qu'il a tourné une première fois.

3. **Fichiers du projet.** Un `CONTRIBUTING.md` qui renvoie vers la charte et un `AGENTS.md` court qui renvoie vers `CONTRIBUTING.md` (R17). Les modèles se trouvent dans ce dépôt.

4. **Écarts.** Tout écart à la charte est noté dans le README du projet (R21) et, s'il est technique, dans un ADR (R25).

## Le chemin de branches (R45)

Le même pour tous les projets : `feature/** → dev → staging → main`. Un projet l'adopte en trois gestes.

1. **Appeler le contrôle de source** : `.github/workflows/flux.yml`.

   ```yaml
   name: Flux de branches
   on:
     pull_request:
       branches: [dev, staging, main]
       types: [opened, edited, reopened, synchronize]
   permissions:
     contents: read
   jobs:
     source:
       name: Branche source autorisée
       uses: abnd-corp/gouvernance/.github/workflows/branche-source.yml@<empreinte>
   ```

   Le contrôle de PR (`gouvernance.yml`) ne vise plus `main` mais `dev` : `branches: [dev]`.

2. **Créer `dev` et `staging` et poser les rulesets** : `scripts/appliquer-flux.sh <depot> [--noms] [contrôles de CI du projet…]`. Le script crée les branches depuis `main`, puis pose les rulesets : `dev` en squash, `staging` et `main` en merge commit, avec la CI obligatoire. Sur un dépôt privé il crée seulement les branches (pas de rulesets sur le plan gratuit).
3. **Noter les écarts** dans le README ou un ADR (R21, R25).

Ce dépôt (`gouvernance`) ne suit pas ce chemin : il ne contient que de la documentation et des workflows, `main` y reçoit des PR en squash avec une review (voir l'ADR 0001).

## Les images de conteneurs (R44)

Le workflow partagé `publier-image.yml` construit une image pour amd64 et arm64 et la pousse sur GHCR (`ghcr.io/abnd-corp/<nom>`). Tag : l'empreinte du commit, plus `X.Y.Z` et `X.Y` quand le commit porte un tag `vX.Y.Z`. Jamais `latest`. Il ne tourne **que lorsqu'une promotion arrive sur `main`**, c'est-à-dire au merge `staging` → `main` : une image par mise en production, pas une par commit ni par tag. Un projet l'appelle ainsi :

```yaml
name: Images
on:
  push:
    branches: [main]
permissions:
  contents: read
  packages: write
jobs:
  api:
    uses: abnd-corp/gouvernance/.github/workflows/publier-image.yml@<empreinte>
    with: { nom: mon-projet-api, contexte: ./api, cible: prod }
  web:
    uses: abnd-corp/gouvernance/.github/workflows/publier-image.yml@<empreinte>
    with: { nom: mon-projet-web, contexte: ./web, cible: prod }
```

Les images sont **privées**. Le premier envoi crée le paquet ; il faut vérifier une fois, dans les réglages du paquet, qu'il est bien privé et lié au dépôt. Un serveur qui tire l'image a besoin d'un jeton de lecture (`read:packages`) : à prévoir au moment du déploiement. Le paramètre `publier: false` construit sans publier, pour un essai.

### Ne pas accumuler d'images

Une image par mise en production, c'est aussi une image de plus à chaque promotion : trois promotions par jour sur deux images, c'est six versions par jour pour un projet. Le plan gratuit limite le stockage des paquets privés (environ 500 Mo, à vérifier dans les réglages de facturation de l'organisation). Trois leviers :

1. **Promouvoir moins souvent.** Une image n'est construite qu'à la promotion sur `main` : regrouper plusieurs fonctionnalités dans une promotion réduit les images sans rien perdre.
2. **Nettoyer automatiquement.** `nettoyer-images.yml` garde les N plus récentes (5 par défaut) et supprime le reste après 4 semaines. Il tourne chaque semaine depuis le projet. Premier lancement en essai (`essai: true`), qui liste sans supprimer.
3. **Des couches partagées.** Un Dockerfile qui sépare installation des dépendances et code fait que deux images successives ne stockent presque que la différence.

Limite connue : avec le jeton du workflow, on ne peut pas exclure les tags de version du nettoyage ; un jeton dédié le permettra plus tard.

## Projets déjà en place

| Projet | État |
|---|---|
| abatelier | Branches `feature → dev → staging → main` (plus strict que la charte), CI propre. À rattacher : contrôle de PR partagé, renvoi vers la charte. |
| Autres projets de l'orga | À rattacher un par un, voir les issues de ce dépôt. |

## Ce qui reste à mettre en place

Ces briques sont prévues par la charte mais n'existent pas encore. Elles viendront par issues, dans l'ordre :

- 2FA obligatoire sur l'orga (R8).
- Secret scanning et push protection sur chaque dépôt (R9).
- Le compte robot `abnd-bot` (R14).
- `org-config` : rulesets, labels et équipes décrits en code (R7). Sur le plan gratuit, il applique le même ruleset à chaque dépôt.
- Les dépôts `template` (R21), `inventaire` privé (R13), et le miroir hors GitHub (R1).
- Renovate et release-please (R23, R24).
- Le kanban d'orga (R6).
