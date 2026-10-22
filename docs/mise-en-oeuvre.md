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
