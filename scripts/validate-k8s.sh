#!/usr/bin/env bash
# Renders what Argo CD would deploy and validates it against the Kubernetes API
# schemas of our cluster version. The same script runs in pre-commit and CI.
#
#   1. Local Helm charts (k8s/charts/*): helm lint, then helm template with
#      each values-<env>.yaml.
#   2. Upstream charts used by the platform Applications
#      (k8s/argocd/envs/<env>/*.yaml): helm template at the pinned version
#      with our values files, plus any plain-manifest sources. This catches a
#      values file that no longer fits the chart before Argo CD does.
#
#   scripts/validate-k8s.sh
#
# Needs: helm, kubeconform, yq (mikefarah); network access for chart and
# schema downloads.
set -euo pipefail

KUBERNETES_VERSION="1.36.0"

# Built-in kinds from the default schema repo; CRDs (Argo CD, Karpenter, ...)
# from the community CRD catalog.
SCHEMA_LOCATIONS=(
  -schema-location default
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
)

cd "$(git rev-parse --show-toplevel)"

kubeconform_check() {
  kubeconform -strict -summary -kubernetes-version "$KUBERNETES_VERSION" "${SCHEMA_LOCATIONS[@]}" "$@"
}

status=0

# ---------------------------------------------------------------- local charts
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
      kubeconform_check; then
      status=1
    fi
  done
done

# ------------------------------------------- upstream charts of platform apps
for app in k8s/argocd/envs/*/*.yaml; do
  # Only multi-source Applications with an upstream chart.
  [[ $(yq '[.spec.sources[]? | select(has("chart"))] | length' "$app") == 1 ]] || continue

  src='.spec.sources[] | select(has("chart"))'
  repo=$(yq "$src | .repoURL" "$app")
  chart=$(yq "$src | .chart" "$app")
  version=$(yq "$src | .targetRevision" "$app")
  release=$(yq "$src | .helm.releaseName" "$app")
  namespace=$(yq '.spec.destination.namespace' "$app")
  echo "==> $app ($chart $version)"

  # Argo CD writes OCI registries without a scheme; helm needs oci://.
  if [[ $repo == *://* ]]; then
    chart_args=("$chart" --repo "$repo")
  else
    chart_args=("oci://$repo/$chart")
  fi

  # $values/<path> refers to this repository.
  values_args=()
  while IFS= read -r file; do
    values_args+=(-f "${file#\$values/}")
  done < <(yq "$src | .helm.valueFiles[]" "$app")

  # Argo CD applies the chart's CRDs too, so they are rendered. The schema
  # repository has no schema for CustomResourceDefinition itself; those come
  # from upstream as published and are checked by the API server.
  if ! {
    helm template "$release" "${chart_args[@]}" --version "$version" \
      --namespace "$namespace" --include-crds "${values_args[@]}"
    # Plain-manifest sources of the same Application.
    while IFS= read -r path; do
      for manifest in "$path"/*.yaml; do
        echo "---"
        cat "$manifest"
      done
    done < <(yq '.spec.sources[] | select(has("path")) | .path' "$app")
  } | kubeconform_check -skip CustomResourceDefinition; then
    status=1
  fi
done

exit "$status"
