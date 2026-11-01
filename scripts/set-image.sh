#!/usr/bin/env bash
# Points one environment's web release at an image: sets image.repository and
# image.tag in k8s/charts/web/values-<env>.yaml. CI runs it to deploy a new
# build to dev and to prepare the promote-to-prod pull request; it works the
# same by hand (for example to roll back to an earlier tag).
#
#   scripts/set-image.sh <env> <repository> <tag>
#   scripts/set-image.sh dev 111122223333.dkr.ecr.ap-southeast-7.amazonaws.com/messagespring/web 3f9c2ab
#
# Tags are short commit SHAs, and ECR tags are immutable, so a tag always means
# the same image.
set -euo pipefail

[[ $# -eq 3 ]] || { sed -n '7,8p' "$0" | sed 's/^# *//'; exit 2; }
env=$1 repository=$2 tag=$3

[[ $env == dev || $env == prod ]] || { echo "env must be dev or prod" >&2; exit 2; }
[[ $repository =~ ^[0-9]{12}\.dkr\.ecr\.[a-z0-9-]+\.amazonaws\.com/[a-z0-9._/-]+$ ]] ||
  { echo "repository must be an ECR repository URL" >&2; exit 2; }
[[ $tag =~ ^[0-9a-f]{7,40}$ ]] || { echo "tag must be a commit SHA" >&2; exit 2; }

cd "$(git rev-parse --show-toplevel)"
# shellcheck source=scripts/lib/set-value.sh
source "scripts/lib/set-value.sh"

file="k8s/charts/web/values-$env.yaml"
set_value "$file" "  repository: " "$repository"
set_value "$file" "  tag: " "\"$tag\""

# Read the result back as YAML: the right keys changed, not just the right lines.
if [[ $(yq '.image.repository + ":" + .image.tag' "$file") != "$repository:$tag" ]]; then
  echo "image in $file is not $repository:$tag after the edit" >&2
  exit 1
fi
echo "$env -> $repository:$tag"
