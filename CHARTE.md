# Charte Abnd

Cette charte fixe les règles de fonctionnement d'Abnd. Elle dit **ce qui est la règle** ; le « comment » technique est dans [docs/mise-en-oeuvre.md](docs/mise-en-oeuvre.md).

Elle est **évolutive** : on la valide telle quelle pour pouvoir avancer, puis on corrige ce qu'on ne veut plus par PR, comme le reste (voir [Faire évoluer la charte](#faire-évoluer-la-charte)). Les numéros (R1, R2…) servent à parler d'une règle sans ambiguïté. Un numéro n'est jamais réutilisé : une règle abandonnée est marquée comme telle.

## Code et GitHub

Tout le code d'Abnd vit sur GitHub, et rien n'arrive sur `main` sans passer par une PR relue.

- **R1 · GitHub est notre forge, sans qu'on en dépende.** Code, tickets, kanban, CI et releases sont sur l'orga GitHub. Un miroir automatique copie tous les repos hors de GitHub, les issues sont exportées régulièrement dans `inventaire`, et la CI tient dans le `Makefile`. Le jour où on décide de s'héberger, rien n'est perdu.
- **R2 · Jamais de push direct sur `dev`, `staging` ni `main`.** Tout changement passe par une branche `feature/…` et une PR.
- **R3 · Une PR = une issue.** La description contient « Closes #N ». Pas d'issue, pas de PR.
- **R4 · On vérifie en local, puis la PR se merge avec une CI verte et une review approuvée.** Avant d'ouvrir une PR, `make check` (lint et tests) passe en local, pour nous comme pour les agents. Un hook de pré-push peut le lancer tout seul. Toutes les PR sont relues. Merge en squash vers `dev` (le message est le titre de la PR), en merge commit pour les promotions (R45).
- **R5 · Conventional Commits.** Les titres de PR vers `dev` commencent par `feat:`, `fix:`, `chore:`… C'est ce qui permet de calculer les versions et le changelog automatiquement.
- **R6 · Le travail se suit dans un seul kanban d'orga, fait des issues elles-mêmes.** Colonnes Backlog → Todo → In progress → In review → Done. Une issue créée arrive seule dans Backlog, la PR qui la ferme la passe en Done : aucune double saisie. Une tâche qui n'y est pas n'existe pas.
- **R45 · Tous les projets suivent le même chemin : `feature/** → dev → staging → main`.** Chaque marche se passe par une PR. `dev` n'accepte que `feature/**` (et `dependabot/**`) et se merge en squash ; `staging` n'accepte que `dev`, et `main` que `staging`, tous deux en merge commit (un squash créerait un commit absent de la branche source et des conflits à la promotion suivante). Une PR ne se merge que si la CI est verte et si le contrôle « Branche source autorisée » passe. Les branches autres que `feature/**` et `dependabot/**` ne se créent pas. La mise en place est décrite dans [docs/mise-en-oeuvre.md](docs/mise-en-oeuvre.md). Un projet qui ne peut pas le suivre l'écrit dans un ADR (R25).
- **R7 · Les règles de l'orga sont du code.** Rulesets, labels, équipes et configs partagées vivent dans `org-config`. On les change par PR, le bot les applique à tous les repos, et chaque changement garde son historique. Fini les réglages cliqués repo par repo.
- **R46 · Pas d'issue sans échéance.** Chaque issue est rattachée à un jalon (milestone) qui a une date d'échéance. C'est obligatoire. GitHub ne peut pas empêcher de créer une issue sans jalon : le bot signale celles qui n'en ont pas, et une issue dont l'échéance est dépassée et qui n'est pas fermée est « en retard » dans le rapport. Repousser une échéance se fait en commentaire, avec la raison.
- **R47 · L'assignation est facultative.** Une issue peut n'avoir personne, une personne ou plusieurs (GitHub en accepte jusqu'à 10). Pour désigner le domaine responsable (R34), on ajoute un label `domaine:<nom>`.

## Sécurité et accès

Un accès se donne nominativement, se trace et se retire le jour du départ.

- **R8 · 2FA obligatoire** pour tous les membres de l'orga GitHub et sur chaque outil qui la propose.
- **R9 · Aucun secret dans le code ni dans un message.** Les mots de passe partagés vivent dans le coffre d'équipe. Le secret scanning bloque un token commité par erreur.
- **R10 · `main` n'accepte que des commits signés.** Tout y arrive par un merge fait depuis GitHub, donc c'est GitHub qui signe. Personne n'a de clé à configurer.
- **R11 · Les comptes appartiennent à l'orga, pas à une personne.** Registrar, hébergement, abonnements : adresse mail de l'orga, jamais un compte perso.
- **R12 · Chaque départ déclenche la checklist de départ.** Retrait des accès, rotation des secrets connus, transfert de ce qui était à son nom. La fiche passe en `statut: parti`, on garde l'historique.
- **R13 · Les données personnelles et clients restent privées.** Elles vivent uniquement dans le repo privé `inventaire`, accessible aux membres seuls.

## Agents et robots

Les agents IA sont des contributeurs comme les autres : ils proposent, un humain valide.

- **R14 · Une seule identité pour les robots.** Tous les agents et automatisations passent par `abnd-bot`. Plus aucun token personnel dans les secrets.
- **R15 · Un agent ne merge jamais seul.** Il ouvre une PR, l'un de nous la relit et l'approuve.
- **R16 · Aucune signature d'IA dans l'historique.** Pas de co-auteur, de signature d'outil ni de mention d'IA dans les commits, les titres ou les descriptions de PR. Un hook local bloque avant le push, et un check de CI refuse la PR. Seul le fichier `AGENTS.md` (R17) montre qu'on utilise des agents.
- **R17 · Une fiche commune pour tous les contributeurs, humains et agents.** Les règles vivent dans `CONTRIBUTING.md`. Un `AGENTS.md` court y renvoie, pour que les agents les trouvent seuls, sans configuration. Les deux viennent de `org-config` et le bot les recopie dans chaque repo. Personne ne les modifie à la main dans un repo.
- **R18 · Un agent ne lit ni n'écrit jamais de secret** (`.env`, clés, tokens). On ne peut pas le prouver à 100 %, donc on verrouille : les réglages des agents leur interdisent ces fichiers, aucun secret de production n'est sur nos machines de dev, et le scanner de secrets (R9) sert de filet. Au moindre doute, on fait tourner le secret.
- **R19 · Pas de nouvelle dépendance sans justification** écrite dans la PR, pour les agents comme pour nous.
- **R39 · Un agent se met à jour en lisant les changelogs, pas sur sa mémoire.** Chaque projet a une fiche `docs/stack.md` : dépendances et outils, versions utilisées, liens vers leurs changelogs. Le bot la tient à jour. Avant de travailler sur un projet, l'agent lit cette fiche et les changelogs des versions utilisées. Quand Dependabot monte une version, il lit les notes de version et signale dans la PR les nouveautés utiles. La consigne est écrite dans `CONTRIBUTING.md`.

## Projets et qualité

Tous les projets partent du même standard, pour qu'on s'y retrouve, nous comme nos agents. Chaque projet peut l'adapter, tant que l'écart est écrit.

- **R20 · Chaque repo a une description, des topics, un README et une licence.** La licence se choisit au cahier des charges du projet ; en attendant, le repo reste privé. Un repo sans licence n'est pas publiable.
- **R21 · Chaque projet part du standard de projet** fourni par le repo `template` : même structure, `Makefile` avec `build`, `test` et `lint`. Un projet peut ajouter ou remplacer ce qu'il veut, tant que ces trois cibles existent. L'écart est noté dans son README.
- **R22 · La CI est partagée entre tous les projets.** Elle est écrite une seule fois (dans ce dépôt pour l'instant), et chaque projet a un fichier de quelques lignes qui l'appelle. Un bug corrigé l'est pour tous. Un projet peut ajouter ses propres étapes par-dessus.
- **R23 · Les versions et le changelog sont proposés par l'outil, validés par nous.** release-please ouvre une PR de release avec la version et le changelog rédigé à partir des commits. Rien n'est publié tant qu'on ne la merge pas, et on peut tout corriger dans la PR.
- **R24 · Les dépendances sont tenues à jour automatiquement, avec prudence.** Dependabot ouvre les PR, mais ne propose une version qu'après 7 jours de quarantaine (`cooldown` dans `dependabot.yml`) ; les correctifs de sécurité passent sans attendre. Seuls les petits correctifs passés par cette quarantaine se mergent seuls si la CI passe, le reste se relit. Les actions GitHub sont figées sur une empreinte exacte, pas sur un tag.
- **R25 · Une décision technique importante s'écrit.** Une page dans `docs/adr/` du repo concerné.
- **R26 · Un projet sans activité depuis 6 mois est revu.** On décide ensemble : on le relance ou on l'archive.

## Livraison et environnements

Tous les projets livrent de la même façon : rien n'arrive en production à la main, et chaque mise en production peut être annulée. Les outils et l'hébergement de chaque projet se choisissent dans un ADR.

- **R40 · Les mêmes noms d'environnements partout** : local, recette (branche `staging`), production (branche `main`). Un projet peut en avoir moins, c'est décidé au cahier des charges (comme R20).
- **R41 · Rien n'arrive en production à la main.** La recette se déploie toute seule depuis `staging`. La production ne se déploie que depuis une release validée (R23) sur `main`, par la CI.
- **R42 · Des secrets séparés par environnement.** Ceux de production ne vivent que dans le coffre et dans la CI, jamais sur une machine de dev (R18).
- **R43 · Toute mise en production prévoit un retour arrière.** Sur un projet client, elle passe par la validation à trois (R35) et elle est tracée (R32).
- **R44 · Les images de conteneurs vivent sur GHCR, privées, publiées uniquement par la CI.** Une image n'est construite que lorsqu'une promotion arrive sur `main` (le merge `staging` → `main`) : jamais sur `dev`, `staging` ni sur une PR. Elle est faite pour amd64 et arm64, taguée avec l'empreinte du commit et, quand le commit porte un tag `vX.Y.Z` (R23), avec sa version (`X.Y.Z`, `X.Y`). Jamais `latest`. Le workflow partagé est `publier-image.yml` (voir [docs/mise-en-oeuvre.md](docs/mise-en-oeuvre.md)). La production pointe vers une version précise, jamais vers `latest`. Personne ne publie d'image depuis sa machine, et chaque image se reconstruit depuis le Dockerfile du repo, donc on peut changer de registre sans rien perdre (R1).

## Membres, outils et clients

Ce que l'orga possède et qui y a accès est écrit quelque part, en un seul endroit.

- **R27 · Chaque membre a une fiche, façon jeu vidéo,** dans `inventaire` : classe, compétences avec un niveau en étoiles, équipement (comptes, clés, machines), quêtes en cours et liste de ses accès. Les niveaux sont déclarés par chacun, à titre indicatif, jamais pour évaluer. Les checklists d'arrivée et de départ en découlent.
- **R28 · Chaque membre a un périmètre indicatif** (un projet ou une brique du plan), déclaré dans les CODEOWNERS. Il sert à proposer un reviewer par défaut ; chacun reste libre de travailler partout.
- **R29 · Un outil absent du catalogue n'est pas un outil de l'orga.** Chaque outil a un admin, une liste d'accès, une licence et une date de renouvellement. Nos outils de dev sont gratuits et open source ; un outil payant est une exception décidée ensemble. En ajouter un, c'est une PR.
- **R30 · Chaque domaine a sa fiche** : registrar, expiration, renouvellement automatique, verrou de transfert. La fiche ne contient que des infos publiques. Le bot lit l'expiration dans l'annuaire public des domaines et prévient 30 jours avant l'échéance. Il ne se connecte jamais au registrar, dont l'accès est limité à nous deux, avec 2FA.
- **R31 · Chaque client a sa fiche** (contact, contrat, niveau de support, projets) et ses tickets portent le label `client:<nom>`.
- **R32 · Chaque déploiement client est tracé** : quel projet, quelle version, quel client, quand. C'est ce qui permet de répondre à « cette faille touche quels clients ? ».
- **R33 · Une décision importante se prend à plusieurs et s'écrit.** Une issue ou un ADR, jamais seulement une discussion orale.

## Rôles et périmètres

Chaque domaine sur lequel on travaille vraiment a un responsable et un suppléant. On reste polyvalents : le responsable n'est pas le seul à y travailler, il veille à ce que ce soit fait.

- **R34 · Sur un projet client ou avec des personnes extérieures, chaque domaine a un responsable et un suppléant.** Le responsable tranche en dernier recours et est reviewer par défaut sur son périmètre (CODEOWNERS). Sur un projet entre nous, c'est facultatif.
- **R35 · Personne n'est seul sur un domaine critique.** Sur la sécurité, l'infra, les accès et la facturation, le suppléant sait reprendre le sujet du jour au lendemain. Une PR y demande une validation à trois : deux personnes plus une review par IA.
- **R36 · La carte des rôles est revue à chaque arrivée ou départ,** et sinon en même temps que la revue des projets dormants (R26), en un quart d'heure. Un domaine marqué « Manque » donne lieu à une décision : quelqu'un le prend, on le confie à un robot ou un outil, on le sous-traite, ou on accepte le manque en connaissance de cause.

### Domaines

| Domaine | Ce que ça couvre | Responsable | Suppléant |
|---|---|---|---|
| Produit et priorités | Quels projets on fait avancer, dans quel ordre, le kanban d'orga | à définir | à définir |
| Développement systèmes | Rust et C : abcom, AbX2T | à définir | à définir |
| Développement web | Vue, TypeScript, HTML : Abyss, abnd, Abloue, Abcarte, Abatelier | à définir | à définir |
| Outillage, CI et agents | Workflows partagés, template, org-config, robots, `CONTRIBUTING.md` et `AGENTS.md` | à définir | à définir |
| Infra et hébergement | Serveurs, déploiements, sauvegardes | à définir | à définir |
| Sécurité | Accès, secrets, failles des dépendances | à définir | à définir |
| Qualité et review | Standard de projet, reviews, ADR | à définir | à définir |
| Organisation | Cette charte, inventaire, outils, arrivées et départs | à définir | à définir |

### À couvrir avant le premier client

Aucun de nous ne maîtrise encore ces sujets, et ce n'est pas un problème tant qu'on n'a pas de client. **Se former est obligatoire** : avant de signer le premier client, on se forme sur chacun d'eux.

- **Comprendre le besoin du client** et le traduire en tickets, puis être son interlocuteur pendant le projet.
- **Devis et contrat** : chiffrer un projet, poser ce qui est inclus ou non.
- **Statut juridique et facturation** : sous quelle structure on facture, et comment.
- **Support après livraison** : comment le client signale un problème, sous quel délai on répond.

## Stack de référence

- **R37 · Un projet utilise la stack de référence.** Une techno hors du cercle « On adopte » demande un ADR qui explique pourquoi, dans le repo concerné.
- **R38 · Une nouvelle techno fait ses preuves en interne avant d'aller chez un client.** Elle passe par « On essaie » sur un de nos projets, puis on décide ensemble de l'adopter ou non.

Le radar (On adopte, On essaie, On évalue, On évite) sera tenu dans `docs/stack.md` de ce dépôt.

## Décisions prises

| Question | Décision | Règles concernées |
|---|---|---|
| Nom de l'orga | `abnd-corp`. | Toutes |
| Review obligatoire pour nos propres PR | Oui, pour toutes. Sur le critique, deux personnes plus l'IA. | R4, R15, R35 |
| Romain et Lucas | Pas membres de l'orga pour l'instant : membres associés, avec un accès au cas par cas sur les repos où ils contribuent. Ça peut évoluer, Lucas en premier vu ce qu'il a déjà apporté. | R27, R28 |
| Repos actifs | Tous restent actifs, y compris abnd, abwatch, Abloue et Abcarte. | R26 |
| Rapports par mail | Depuis une adresse du domaine abnd. Avancement le lundi, santé le 1er du mois. | R11 |
| Visibilité de l'IA dans les repos | `AGENTS.md` assumé dans chaque repo, aucune signature d'IA dans l'historique. | R16, R17 |
| Formation avant le premier client | Obligatoire. | Rôles et périmètres |
| Flux de branches | `feature/** → dev → staging → main` pour tous les projets, comme Abatelier. | R2, R4, R45 |
| Images de conteneurs | Sur GHCR, privées. Le jeton de lecture pour les serveurs est prévu plus tard. | R44 |
| Échéance des issues | Obligatoire, portée par la date d'un jalon. L'assignation reste facultative, à plusieurs si besoin. | R46, R47 |
| Offre GitHub payante | Non. On reste sur le plan gratuit : pas de rulesets d'organisation, chaque dépôt public a le sien (voir [docs/mise-en-oeuvre.md](docs/mise-en-oeuvre.md)). | R7, R22 |

## Faire évoluer la charte

La charte n'est pas figée. Pour changer une règle : une issue qui explique pourquoi, puis une PR sur ce dépôt qui modifie `CHARTE.md` (R33). Une règle abandonnée garde son numéro, marquée « abandonnée » avec la date et la raison. Quand une règle change, les projets qui l'appliquent sont adaptés ensuite, par leurs propres PR.

## Validation

La charte est adoptée dans sa version v2 par Rudy et Hugo, le 23 octobre 2026. Elle reste évolutive : ce qui gêne se corrige par PR, et les points secondaires se traitent le moment venu.
