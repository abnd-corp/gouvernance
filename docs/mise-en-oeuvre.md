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

   La charte demande de figer un workflow externe sur une empreinte exacte (R24) : remplacer `main` par l'empreinte du commit de ce dépôt dès qu'une version est validée. Dependabot la met ensuite à jour.

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

## Les échéances (R46)

GitHub n'a pas de date d'échéance propre à une issue. Dans la charte, l'échéance d'une issue est **la date du jalon auquel elle appartient** : un jalon (milestone) avec une date de fin. C'est natif, visible dans la liste des issues, et interrogeable par le bot.

- Créer un jalon : onglet *Issues* → *Milestones* → *New milestone*, avec une **Due date**.
- Rattacher une issue : colonne de droite de l'issue → *Milestone*.
- Une échéance plus fine qu'un jalon existant se fait avec un jalon court (par exemple « Semaine du 3 novembre »).
- Quand le kanban d'orga existera (R6), son champ « Échéance » pourra remplacer le jalon : la règle ne change pas, seul l'endroit où l'on lit la date.

Les issues sans jalon daté ne sont pas bloquées : le bot les liste dans le rapport des issues, et les modèles d'issue rappellent d'indiquer l'échéance.

## Le contrôle de PR partagé (R3, R5, R16)

Le workflow `controle-pr.yml` vérifie trois choses : le titre en Conventional Commits (R5), l'absence de signature d'IA (R16) et, pour une PR de branche `feature/**`, la présence de « Closes #N » dans la description (R3). Les promotions et les PR de Dependabot ne sont pas concernées par R3.

Chaque projet appelle ce workflow sur une version précise (empreinte de commit, R24) : le contrôle R3 n'arrive chez lui qu'avec la montée de version proposée par Dependabot. Il n'est ajouté aux contrôles obligatoires des rulesets (`org-config`) qu'une fois les projets à jour, pour ne bloquer personne.

## Fermer les issues au merge dans `dev` (R3, R6)

Le workflow partagé `fermer-issues.yml` ferme, dès le merge d'une PR dans `dev`, les issues du même dépôt qu'elle cite par « Closes #N ». Le projet d'orga passe alors la carte en Done tout seul. Chaque dépôt l'appelle par un fichier `.github/workflows/fermer-issues.yml` :

```yaml
name: Fermer les issues
on:
  pull_request:
    types: [closed]
    branches: [dev]
permissions:
  contents: read
  issues: write
jobs:
  fermer:
    if: github.event.pull_request.merged == true
    uses: abnd-corp/gouvernance/.github/workflows/fermer-issues.yml@<empreinte>
```

Le passage horaire du bot reste en filet de sécurité : issues d'un autre dépôt, PR dont le workflow n'a pas tourné.

## Qui peut merger quoi (R4, R15, R48)

- **Rudy et Hugo décident chacun seul** (R48). Aucun ruleset n'exige d'approbation sur nos propres PR : `required_approving_review_count` est à 0 sur `gouvernance`, `abnd` et `abatelier`. La CI reste obligatoire.
- **Un agent peut merger** une PR, promotions jusqu'à `main` comprises, quand un humain le lui demande explicitement et que la CI est verte à chaque marche (R15). Il ne le fait jamais de sa propre initiative.
- **Une PR de montée de dépendances** n'a pas besoin d'un second reviewer (R4).
- Pour que le merge soit possible, le ruleset ne doit pas exiger de revue : si GitHub répond « base branch policy prohibits the merge », vérifier d'abord `required_approving_review_count`.

## Le compte du bot : une GitHub App (R14)

Il n'y a pas de compte utilisateur `abnd-bot`. L'identité du bot est une **GitHub App** de l'organisation, `abnd-bot` (App ID `5460286`), installée sur tous les dépôts.

- Droits : Metadata, Dependabot alerts, Checks et Commit statuses en lecture ; Contents, Pull requests et Issues en écriture ; Organization projects en écriture. Pas d'Administration, pas de Secrets, pas de Members.
- Le dépôt `bot` garde la variable `APP_ID` et le secret `APP_PRIVATE_KEY`. Le workflow `alertes.yml` demande un jeton d'installation à chaque passage (`actions/create-github-app-token`, figée sur son empreinte).
- La clé privée n'existe qu'en secret du dépôt `bot` : elle n'est ni sur un disque ni dans un message. Si elle est perdue ou compromise, on en génère une autre dans les réglages de l'App et on remplace le secret.
- Les actions d'un agent de code passent pour l'instant par le compte de la personne qui l'utilise.

## Le kanban d'orga (R6)

Le projet [Abnd](https://github.com/orgs/abnd-corp/projects/2) regroupe les issues de tous les dépôts. Colonnes : Backlog, Todo, In progress, Done. Les automatismes du projet sont activés : une issue ajoutée arrive en Backlog, une PR liée la passe en In progress, la fermeture ou le merge la passe en Done.

Le plan gratuit n'autorise qu'une règle d'ajout automatique par projet, et « Closes #N » ne ferme une issue que si la PR est mergée dans la branche par défaut (`main`), alors que nos PR vont vers `dev`. C'est donc le **bot** qui tient le projet : le workflow `kanban.yml` du dépôt `bot` passe chaque heure (minute 30), ajoute en Backlog les issues ouvertes absentes du projet, et met en Done puis ferme celles qu'une PR mergée annonce fermer (« Closes #N », fenêtre de 30 jours). Une issue peut donc rester ouverte jusqu'à une heure après le merge de sa PR.

## Classer les dépôts : la propriété `type`

Chaque dépôt de l'orga porte une propriété personnalisée `type` (Settings de l'orga → Custom properties). Trois valeurs :

| Valeur | Sens | Dépôts |
|---|---|---|
| `gestion` | Ce qui fait fonctionner l'orga elle-même | gouvernance, org-config, template, inventaire, bot, Documentation |
| `projet` | Un produit réel | Abatelier, AbSante, Abnd, Abvance, Abyss, Abcom, AbX2T, Abcarte, Abloue, Abwatch |
| `test` | Un dépôt d'essai | abflow-skill-doc-test |

Pour filtrer la liste des dépôts : `props.type:projet` dans la barre de recherche. Un nouveau dépôt reçoit sa valeur à sa création ; la propriété peut servir plus tard à cibler des rulesets.

## Projets déjà en place

| Projet | État |
|---|---|
| abatelier | Branches `feature → dev → staging → main`, CI propre, contrôle de PR partagé, Dependabot (sans quarantaine à ce jour). |
| abnd | Chemin de branches commun en place, contrôle de PR partagé. Dependabot en cours (PR ouverte). |
| bot | Chemin de branches commun, `AGENTS.md`, Dependabot (sans quarantaine à ce jour). |
| gouvernance | `main` seul, PR en squash, 0 approbation exigée (R48). |
| AbSante | Son ruleset d'origine, pas celui d'`org-config` : le contrôle « Branche source autorisée » refuserait la PR quotidienne des données RPPS, qui vise `main` (décision du 25 octobre). Il n'exige plus que la branche soit à jour avec `main`, ce qui bloquait les promotions. |
| Autres projets de l'orga | À rattacher un par un, voir les issues de ce dépôt. |

## Ce qui est en place

- 2FA obligatoire sur l'orga (R8).
- Dépôts `org-config`, `template`, `inventaire` (privé) et `bot` créés. Le contenu de `org-config` et de `template` reste à vérifier.
- GitHub App du bot (R14), kanban d'orga (R6), merge par un agent encadré (R15).
- Dependabot avec quarantaine de 7 jours dans tous les dépôts publics (R24), et « Dependabot security updates » activé sur chacun : les correctifs de sécurité ouvrent une PR sans attendre la quarantaine.
- Contrôle « Closes #N » dans le contrôle de PR partagé (R3). Il n'est pas encore obligatoire dans les rulesets : à faire quand les projets auront mis à jour leur version du contrôle.

## Ce qui reste à mettre en place

Ces briques sont prévues par la charte mais n'existent pas encore. Elles viendront par issues :

- **Sauvegarde hors GitHub (R1)** : miroir des dépôts, export des issues, PR et kanban, et `docs/reprise.md`. Deux copies indépendantes, sur la Raspberry de Rudy et sur le serveur de Hugo. Chaque copie va chercher les données sur GitHub en lecture seule, garde des instantanés datés sans jamais écraser les précédents, et supprime ceux de plus de 12 semaines.
- Secret scanning et push protection sur chaque dépôt (R9).
- `org-config` : rulesets, labels et équipes décrits en code (R7).
- release-please (R23).
- `docs/stack.md` par projet et radar de stack (R39, R37, R38).

## Accès à l'orga

Trois propriétaires : Rudy, Hugo et Lucas-ui. C'est un choix assumé (25 octobre 2026) : Lucas-ui reste propriétaire. Romain n'est pas membre.
