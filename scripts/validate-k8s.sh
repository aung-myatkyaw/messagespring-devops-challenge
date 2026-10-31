#!/usr/bin/env bash
# Renders every local Helm chart with each of its values-<env>.yaml files and
# validates the output against the Kubernetes API schemas of our cluster
# version. The same script runs in pre-commit and CI.
#
#   scripts/validate-k8s.sh
#
# Needs: helm, kubeconform.
set -euo pipefail

KUBERNETES_VERSION="1.36.0"

# Built-in kinds from the default schema repo; CRDs (Argo CD, Karpenter, ...)
# from the community CRD catalog.
SCHEMA_LOCATIONS=(
  -schema-location default
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
)

cd "$(git rev-parse --show-toplevel)"

status=0
for chart in k8s/charts/*/; do
  chart=${chart%/}
  for values in "$chart"/values-*.yaml; do
    env=$(basename "$values" .yaml)
    env=${env#values-}
    echo "==> $chart ($env)"

    if ! helm lint --strict "$chart" -f "$values" >/dev/null; then
      helm lint --strict "$chart" -f "$values" || true
      status=1
      continue
    fi

    # The release name and namespace match the Argo CD Application.
    if ! helm template "$(basename "$chart")" "$chart" -f "$values" --namespace "$(basename "$chart")" |
      kubeconform -strict -summary -kubernetes-version "$KUBERNETES_VERSION" "${SCHEMA_LOCATIONS[@]}"; then
      status=1
    fi
  done
done

exit "$status"
