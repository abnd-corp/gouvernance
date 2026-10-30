# Gouvernance Abnd

Ce dépôt est la source de vérité des règles de l'organisation [abnd-corp](https://github.com/abnd-corp). Tous les projets s'y rattachent.

| Fichier | Rôle |
|---|---|
| [CHARTE.md](CHARTE.md) | Les règles (R1 à R49) : ce qui est la règle |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Comment contribuer, pour les humains et les agents |
| [docs/mise-en-oeuvre.md](docs/mise-en-oeuvre.md) | Comment un projet se rattache à la gouvernance |
| [docs/adr/](docs/adr/) | Les décisions de gouvernance, une page chacune |
| `.github/workflows/controle-pr.yml` | Workflow partagé : contrôle du titre et des signatures d'IA (R5, R16) |
| [SECURITY.md](SECURITY.md) | Signaler une faille |

## Rattacher un projet

Un projet appelle les workflows de ce dépôt en quelques lignes et renvoie vers la charte depuis son `CONTRIBUTING.md`. Le pas à pas est dans [docs/mise-en-oeuvre.md](docs/mise-en-oeuvre.md).

## Faire évoluer les règles

Une issue, puis une PR sur `CHARTE.md`. Voir « Faire évoluer la charte » dans la charte. Rien n'est poussé directement sur `main`.

Rien de confidentiel ne va dans ce dépôt, qui est public : pas de secret, pas de donnée personnelle ni de donnée client (R13).
