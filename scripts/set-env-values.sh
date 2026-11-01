#!/usr/bin/env bash
# Writes one environment's account-specific values into the Kubernetes values
# files that Argo CD deploys. The committed files hold placeholders (account
# 123456789012, zone example.com) until this is run for a real deployment.
#
#   scripts/set-env-values.sh <env> <aws-account-id> <cloudflare-zone> [hostname]
#   scripts/set-env-values.sh dev 111122223333 example.org
#
# hostname defaults to messagespring-dev.<zone> (dev) or messagespring.<zone>
# (prod) and must equal app_hostname in infra/envs/<env>/terraform.tfvars:
# the ACM certificate is issued for that name.
#
# Bucket and repository names follow the naming in infra/modules/log-storage
# and infra/envs/shared. Safe to re-run: it rewrites whole values, not the
# placeholder text. Review the diff and commit it.
set -euo pipefail

usage() {
  sed -n '6,7p' "$0" | sed 's/^# *//'
  exit 2
}

[[ $# -eq 3 || $# -eq 4 ]] || usage
env=$1 account=$2 zone=$3

[[ $env == dev || $env == prod ]] || { echo "env must be dev or prod" >&2; exit 2; }
[[ $account =~ ^[0-9]{12}$ ]] || { echo "AWS account ID must be 12 digits" >&2; exit 2; }
[[ $zone =~ ^([a-z0-9-]+\.)+[a-z]{2,}$ ]] || { echo "zone must be a domain name like example.org" >&2; exit 2; }

if [[ $env == prod ]]; then
  default_host="messagespring.$zone"
else
  default_host="messagespring-$env.$zone"
fi
host=${4:-$default_host}
[[ $host == *".$zone" ]] || { echo "hostname must be inside the zone $zone" >&2; exit 2; }

region="ap-southeast-7"
suffix="$account-$region"

cd "$(git rev-parse --show-toplevel)"

# shellcheck source=scripts/lib/set-value.sh
source "scripts/lib/set-value.sh"

web="k8s/charts/web/values-$env.yaml"
loki="k8s/platform/loki/values-$env.yaml"
external_dns="k8s/platform/external-dns/values-$env.yaml"

# The image tag is left alone: CI writes it after each build.
set_value "$web" "  repository: " "$account.dkr.ecr.$region.amazonaws.com/messagespring/web"
set_value "$web" "  host: " "$host"
set_value "$web" "  accessLogsBucket: " "messagespring-$env-alb-logs-$suffix"
set_value "$loki" "      chunks: " "messagespring-$env-loki-chunks-$suffix"
set_value "$loki" "      ruler: " "messagespring-$env-loki-ruler-$suffix"
set_value "$external_dns" "domainFilters: " "[$zone]"

echo "Set $env values (account $account, host $host). Review with: git diff k8s"
