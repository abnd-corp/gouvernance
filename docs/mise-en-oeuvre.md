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

2. **Créer `dev` et `staging` et poser les rulesets** : `scripts/appliquer-flux.sh <depot> [--noms] [contrôles de CI du projet…]`. Le script active d'abord la suppression des branches fusionnées (R49), crée les branches depuis `main`, puis pose les rulesets : `dev` en squash, `staging` et `main` en merge commit, avec la CI obligatoire. Sur un dépôt privé il crée seulement les branches (pas de rulesets sur le plan gratuit).
3. **Noter les écarts** dans le README ou un ADR (R21, R25).

Ce dépôt (`gouvernance`) ne suit pas ce chemin : il ne contient que de la documentation et des workflows, `main` y reçoit des PR en squash avec une review (voir l'ADR 0001).

## Les images de conteneurs (R44)

Une image est construite **une fois**, à la fusion dans `dev`, puis promue sans reconstruction jusqu'à la production. Trois workflows partagés le font (build, promotion, nettoyage), et un script (`scripts/images.sh`) porte la logique. Le modèle de projet (`template`) les appelle déjà : sans `.github/images/services.json`, ils ne font rien, donc un projet sans conteneur peut les garder. Le modèle vient de traintracks ; la décision est dans l'[ADR 0002](adr/0002-images-promues-sans-reconstruction.md).

**1. Décrire les services** dans `.github/images/services.json` du projet :

```json
{
  "projet": "mon-projet",
  "plateformes": "linux/amd64,linux/arm64",
  "services": {
    "api": {
      "image": "mon-projet-api",
      "contexte": ".",
      "dockerfile": "api/Dockerfile",
      "sources": ["api", "shared", ".dockerignore"],
      "build_args": ["APP_VERSION={court}", "APP_COMMIT={commit}"]
    }
  }
}
```

`sources` liste ce qui entre dans l'image : leur empreinte git donne le tag `c-<empreinte>` du service. Si cette image existe déjà, le service n'est pas reconstruit. `{commit}` et `{court}` sont remplacés dans `build_args`.

**2. Appeler les workflows.** `<empreinte>` est le même commit de `gouvernance` dans `uses:` et dans `with:` : c'est lui qui fournit `scripts/images.sh`.

```yaml
# .github/workflows/images.yml : fusion dans dev
name: Images
on:
  push:
    branches: [dev]
jobs:
  tests:
    uses: ./.github/workflows/tests.yml
  images:
    needs: tests
    permissions: { contents: read, packages: write }
    uses: abnd-corp/gouvernance/.github/workflows/images-dev.yml@<empreinte>
    with: { gouvernance: <empreinte> }
```

```yaml
# .github/workflows/promotion.yml : staging, production, version
name: Promotion
on:
  push:
    branches: [staging, main]
    tags: ["v[0-9]+.[0-9]+.[0-9]+"]
jobs:
  promotion:
    permissions: { contents: write, packages: write }
    uses: abnd-corp/gouvernance/.github/workflows/promouvoir-images.yml@<empreinte>
    with: { gouvernance: <empreinte> }
```

**3. Ce qui se passe à chaque marche**

| Événement | Effet sur les images |
|---|---|
| Fusion dans `dev` | Build des services changés, tag `dev`, manifeste publié |
| Fusion dans `staging` | Tag `staging` sur les images de `dev` |
| Fusion dans `main` | Tag `prod` |
| Tag `vX.Y.Z` sur `main` | Tag `vX.Y.Z` et release GitHub avec le manifeste |

Le **manifeste** liste, pour un commit, l'image et le digest exacts de chaque service. Il est publié sur GHCR (`<projet>-manifeste`) et joint à la release : c'est la trace de ce qui tourne (R32). Il n'y a pas de date dedans : pour un même commit, il est identique d'une étape à l'autre.

**Poser une version** : `scripts/poser-version.sh X.Y.Z` pose le tag `vX.Y.Z` sur `main` (donc sur ce qui est en production) et le pousse ; la CI fait le reste. Un projet l'expose en `make release V=X.Y.Z`. Le workflow refuse un tag qui n'est pas sur `main`.

Les images sont **privées**. Le premier envoi crée le paquet ; il faut vérifier une fois, dans les réglages du paquet, qu'il est bien privé et lié au dépôt. Un serveur qui tire l'image a besoin d'un jeton de lecture (`read:packages`) : à prévoir au moment du déploiement.

### Ne pas accumuler d'images

On construit à chaque fusion dans `dev`, donc les images s'accumulent plus vite qu'avec un build à la promotion. Le plan gratuit limite le stockage des paquets privés (environ 500 Mo, à vérifier dans les réglages de facturation de l'organisation). Trois leviers :

1. **Ne reconstruire que ce qui change.** L'empreinte par service fait qu'un service inchangé réutilise son image.
2. **Nettoyer automatiquement.** Le workflow partagé `nettoyer-images-non-promues.yml` (exemple d'appel en tête du fichier, chaque lundi) lance `scripts/images.sh nettoyer <jours> <essai>`, qui supprime les images qui ne portent ni `dev`, `staging`, `prod` ni une version, au-delà de `<jours>` jours, et protège les couches des images multi-architecture. Premier lancement en essai (`essai=true`), qui liste sans supprimer. Il garde les versions `vX.Y.Z`, ce que `nettoyer-images.yml` ne sait pas faire.
3. **Des couches partagées.** Un Dockerfile qui sépare installation des dépendances et code fait que deux images successives ne stockent presque que la différence.

> **Ne pas combiner avec `nettoyer-images.yml`** : il garde les N plus récentes sans connaître les tags d'étape, et peut supprimer l'image de `prod` si elle est ancienne. Dans ce modèle, on nettoie avec `nettoyer-images-non-promues.yml`. Pour qu'il puisse supprimer, le dépôt doit avoir le rôle **Admin** sur chaque paquet (réglages du paquet, « Manage Actions access ») ; sans lui, il ne fait que lister.

### L'ancien modèle : `publier-image.yml`

`publier-image.yml` construit à la promotion sur `main`, une image par mise en production. Il reste en place pour les projets qui l'utilisent déjà (rien ne casse), mais n'est plus la référence : un nouveau projet prend `images-dev.yml` et `promouvoir-images.yml`.

## Les échéances (R46)

GitHub n'a pas de date d'échéance propre à une issue. Dans la charte, l'échéance d'une issue est **la date du jalon auquel elle appartient** : un jalon (milestone) avec une date de fin. C'est natif, visible dans la liste des issues, et interrogeable par le bot.

- Créer un jalon : onglet *Issues* → *Milestones* → *New milestone*, avec une **Due date**.
- Rattacher une issue : colonne de droite de l'issue → *Milestone*.
- Une échéance plus fine qu'un jalon existant se fait avec un jalon court (par exemple « Semaine du 3 novembre »).
- Quand le kanban d'orga existera (R6), son champ « Échéance » pourra remplacer le jalon : la règle ne change pas, seul l'endroit où l'on lit la date.

Les issues sans jalon daté ne sont pas bloquées : le bot les liste dans le rapport des issues, et les modèles d'issue rappellent d'indiquer l'échéance.

## Le contrôle de PR partagé (R3, R5, R16)

Le workflow `controle-pr.yml` vérifie trois choses : le titre en Conventional Commits (R5), l'absence de signature d'IA (R16) et, pour une PR de branche `feature/**`, la présence de « Closes #N » dans la description (R3). Les promotions et les PR de Dependabot ne sont pas concernées par R3.

Chaque projet appelle ce workflow sur une version précise (empreinte de commit, R24) : le contrôle R3 n'arrive chez lui qu'avec la montée de version. Il est **obligatoire sur `dev`** (option `closes` de `depots.json` dans `org-config`) pour les dépôts qui appellent la version du contrôle qui le porte : Abnd, Abatelier, Abloue, Abyss, Abvance, Abwatch et template. Une PR sans « Closes #N » y est refusée par GitHub. Abcom, AbX2T et Abcarte ne l'ont pas encore (CI rouge pour les deux premiers, issues désactivées sur Abcarte). Pour rendre le contrôle obligatoire dans un dépôt : mettre à jour son appel au contrôle de PR, puis passer `closes` à `true` dans `depots.json` et lancer `scripts/appliquer.sh <depot>`.

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
- Secret scanning et push protection (R9) sur les 14 dépôts publics, et par défaut sur tout nouveau dépôt de l'orga (avec les alertes et correctifs de sécurité Dependabot). Les dépôts privés (`bot`, `inventaire`, `Documentation`) n'y ont pas droit sur le plan gratuit : R9 y repose sur la discipline (R18).
- Dependabot avec quarantaine de 7 jours dans tous les dépôts publics (R24), et « Dependabot security updates » activé sur chacun : les correctifs de sécurité ouvrent une PR sans attendre la quarantaine.
- Contrôle « Closes #N » dans le contrôle de PR partagé (R3), obligatoire sur `dev` dans 7 dépôts (voir plus haut).
- Checklist de départ (R12) : [depart.md](depart.md).

## Un départ (R12)

La checklist est dans [depart.md](depart.md), avec un modèle d'issue « Départ d'un membre ». Elle couvre les accès GitHub, les secrets à changer (clé de l'App, jeton Matrix), les serveurs, les comptes à son nom et la fiche `inventaire`.

## Ce qui reste à mettre en place

Ces briques sont prévues par la charte mais n'existent pas encore. Elles viendront par issues :

- **Sauvegarde hors GitHub (R1)** : miroir des dépôts, export des issues, PR et kanban, et `docs/reprise.md`. Deux copies indépendantes, sur la Raspberry de Rudy et sur le serveur de Hugo. Chaque copie va chercher les données sur GitHub en lecture seule, garde des instantanés datés sans jamais écraser les précédents, et supprime ceux de plus de 12 semaines.
- `org-config` : rulesets, labels et équipes décrits en code (R7).
- release-please (R23).
- `docs/stack.md` par projet et radar de stack (R39, R37, R38).

## Accès à l'orga

Trois propriétaires : Rudy, Hugo et Lucas-ui. C'est un choix assumé (25 octobre 2026) : Lucas-ui reste propriétaire. Romain n'est pas membre.
