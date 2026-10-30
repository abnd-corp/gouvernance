#!/usr/bin/env bash
# Applique le chemin feature/** → dev → staging → main (R45) à un dépôt de l'orga :
# active la suppression des branches fusionnées (R49), crée dev et staging depuis main s'ils manquent, puis pose les rulesets (dépôts publics seulement,
# les rulesets ne sont pas disponibles sur un dépôt privé du plan gratuit).
#
# Usage : scripts/appliquer-flux.sh <depot> [--noms] [contrôle de CI obligatoire…]
#   --noms : interdit aussi la création de toute branche autre que feature/** et dependabot/**
#            (à éviter quand des automatisations créent leurs propres branches).
# Prérequis : le dépôt appelle .github/workflows/gouvernance.yml (contrôle de PR) et
#             .github/workflows/flux.yml (branche source), voir docs/mise-en-oeuvre.md.
set -euo pipefail

depot="${1:?usage: appliquer-flux.sh <depot> [--noms] [contrôles…]}"; shift
noms=false; if [ "${1:-}" = "--noms" ]; then noms=true; shift; fi
org=abnd-corp
api() { gh api "$@"; }

visibilite=$(api "repos/$org/$depot" --jq .visibility)
[ "$visibilite" = public ] || { echo "$depot est privé : rulesets indisponibles sur le plan gratuit, branches créées seulement."; }

# R49 : GitHub supprime la branche d'une PR dès qu'elle est fusionnée (dev, staging et main restent : elles sont protégées)
api -X PATCH "repos/$org/$depot" -F delete_branch_on_merge=true --jq '"= suppression des branches fusionnées : \(.delete_branch_on_merge)"'

base=$(api "repos/$org/$depot" --jq .default_branch)
sha=$(api "repos/$org/$depot/git/ref/heads/$base" --jq .object.sha)
for b in dev staging; do
  if api "repos/$org/$depot/git/ref/heads/$b" --jq .ref >/dev/null 2>&1; then echo "= branche $b existe déjà"
  else api -X POST "repos/$org/$depot/git/refs" -f ref="refs/heads/$b" -f sha="$sha" --jq .ref; fi
done
[ "$visibilite" = public ] || exit 0

# Contrôles obligatoires : ceux de la gouvernance + ceux du projet
source="Branche source autorisée / Branche source autorisée"
checks_dev=("$source" "Contrôle des PR / Titre en Conventional Commits" "Contrôle des PR / Aucune signature d'IA" "$@")
checks_promo=("$source" "$@")

json_checks() { printf '%s\n' "$@" | jq -R '{context: ., integration_id: 15368}' | jq -s .; }
existe() { api "repos/$org/$depot/rulesets" --jq ".[].name" | grep -Fxq "$1"; }

poser() { # nom, branches (JSON), méthodes de merge (JSON), contrôles (JSON)
  if existe "$1"; then echo "= ruleset « $1 » existe déjà"; return; fi
  jq -n --arg nom "$1" --argjson inc "$2" --argjson meth "$3" --argjson chk "$4" '{
    name: $nom, target: "branch", enforcement: "active",
    conditions: {ref_name: {include: $inc, exclude: []}},
    bypass_actors: [],
    rules: [
      {type: "deletion"}, {type: "non_fast_forward"},
      {type: "pull_request", parameters: {required_approving_review_count: 0, dismiss_stale_reviews_on_push: false, require_code_owner_review: false, require_last_push_approval: false, required_review_thread_resolution: true, allowed_merge_methods: $meth}},
      {type: "required_status_checks", parameters: {strict_required_status_checks_policy: false, do_not_enforce_on_create: false, required_status_checks: $chk}}
    ]}' | api -X POST "repos/$org/$depot/rulesets" --input - --jq '"+ ruleset « \(.name) »"'
}

poser "dev : PR depuis feature/**, squash" '["refs/heads/dev"]' '["squash"]' "$(json_checks "${checks_dev[@]}")"
poser "staging et main : PR de promotion, merge commit" '["refs/heads/staging","refs/heads/main"]' '["merge"]' "$(json_checks "${checks_promo[@]}")"

if $noms && ! existe "Noms de branche : feature/** (et dependabot/**) uniquement"; then
  jq -n '{name: "Noms de branche : feature/** (et dependabot/**) uniquement", target: "branch", enforcement: "active",
    conditions: {ref_name: {include: ["~ALL"], exclude: ["refs/heads/dev","refs/heads/staging","refs/heads/main","refs/heads/feature/**","refs/heads/dependabot/**"]}},
    bypass_actors: [], rules: [{type: "creation"}]}' | api -X POST "repos/$org/$depot/rulesets" --input - --jq '"+ ruleset « \(.name) »"'
fi
