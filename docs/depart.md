# Départ d'un membre (R12)

Un départ déclenche cette checklist le jour même : on ouvre une issue avec le modèle « Départ d'un membre », et on coche chaque ligne. Rien ne se supprime : on retire des accès, on change ce que la personne connaissait, on garde l'historique.

Les commandes `gh` ci-dessous se lancent depuis le terminal d'un propriétaire de l'orga.

## 1. Accès GitHub

- [ ] Garder **au moins deux propriétaires** : si la personne en est une, en nommer un autre avant de la retirer (*Settings → People*).
- [ ] La retirer de l'organisation (*Settings → People → Remove*), ou la rétrograder en membre associé si elle continue de contribuer (R27).
- [ ] Vérifier qu'elle n'est plus collaboratrice extérieure : `gh api orgs/abnd-corp/outside_collaborators --jq '.[].login'`.
- [ ] Révoquer ses jetons personnels qui touchent l'orga : *Settings de l'orga → Personal access tokens*.
- [ ] Retirer son nom des `CODEOWNERS` (dépôt `gouvernance` et projets) et des PR ou issues qui lui sont assignées.
- [ ] Vérifier les clés de déploiement des dépôts : `gh api repos/abnd-corp/<depot>/keys --jq '.[].title'`.

## 2. Secrets qu'elle connaissait

On change tout ce qu'elle a pu voir ou copier, même si on ne pense pas qu'elle l'ait fait.

- [ ] **App GitHub `abnd-bot`** : générer une nouvelle clé privée (*Settings de l'orga → Developer settings → GitHub Apps*), la poser dans le secret `APP_PRIVATE_KEY` du dépôt `bot`, puis supprimer l'ancienne clé dans l'App.
- [ ] **Matrix** : générer un nouveau jeton pour le compte du bot et remplacer le secret `MATRIX_TOKEN`. Changer le mot de passe du compte si elle le connaissait.
- [ ] Les autres secrets de dépôts ou d'environnements qu'elle pouvait lire, et les mots de passe du coffre d'équipe (R9).
- [ ] Aucun secret ne vit sur un poste (R18, R42) : si elle en avait un de production en local, le changer.

## 3. Serveurs et outils

- [ ] Retirer sa clé SSH des serveurs (`~/.ssh/authorized_keys`) : la Raspberry de Rudy, le serveur de Hugo, tout hébergement.
- [ ] La retirer des salons Matrix de l'orga.
- [ ] La retirer de chaque outil du catalogue (R29) : registrar, hébergement, abonnements.

## 4. Ce qui était à son nom (R11)

Les comptes appartiennent à l'orga, pas à une personne. S'il en reste un à son nom :

- [ ] Le transférer à l'adresse de l'orga (registrar, hébergement, abonnements, domaines).
- [ ] Réattribuer les projets, domaines et tâches dont elle était responsable (R34, quand les rôles seront nommés).

## 5. Fiche et trace

- [ ] Passer sa fiche de `inventaire` en `statut: parti`, avec la date : on garde la fiche et son historique (R27).
- [ ] Vérifier une dernière fois : `gh api orgs/abnd-corp/members --jq '.[].login'`.
- [ ] Fermer l'issue de départ, avec le jalon à la date du départ (R46).
