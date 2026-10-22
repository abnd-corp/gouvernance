# ADR 0001 · Un dépôt `gouvernance`, public, plan GitHub gratuit

Date : 22 octobre 2026 · Statut : accepté

## Contexte

La charte d'Abnd vivait dans des documents partagés. Elle doit s'appliquer à tous les projets de l'organisation, être versionnée et se modifier par PR (R33). On ne prend pas l'offre GitHub payante.

## Décision

- Un dépôt `abnd-corp/gouvernance` porte la charte, les modèles et les workflows partagés.
- Il s'appelle `gouvernance` plutôt que `.github` : le nom est plus lisible. Contrepartie : GitHub ne diffuse pas ses fichiers automatiquement aux autres dépôts.
- Il est public : les workflows partagés sont ainsi appelables par les autres dépôts sans réglage, et la charte ne contient rien de confidentiel (R13).
- Le plan gratuit n'a pas de rulesets d'organisation : chaque dépôt public reçoit le même ruleset, et les projets se rattachent en appelant les workflows partagés (voir [mise-en-oeuvre](../mise-en-oeuvre.md)).
- La charte est adoptée telle quelle puis corrigée par PR : elle est évolutive, pas figée.

## Conséquences

- Un nouveau dépôt demande de copier son ruleset et son workflow d'appel : tant qu'`org-config` (R7) n'existe pas, c'est manuel.
- Si l'offre payante est prise un jour, on passe à des rulesets d'orga et éventuellement à un dépôt `.github`, sans changer la charte.
- Si le dépôt devient privé, les workflows partagés demandent un réglage d'accès explicite sur chaque dépôt.
