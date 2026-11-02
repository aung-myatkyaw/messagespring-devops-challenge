#!/usr/bin/env bash
# Installs CLI tools for CI jobs at pinned versions, checking each download
# against its published SHA-256 so a replaced release asset fails the job.
# All CI tool versions that aren't set by an action live here, in one place.
#
#   scripts/install-ci-tools.sh <tool>...      (gitleaks helm hadolint kubeconform yq)
#
# Installs into $RUNNER_TEMP/bin and puts that first on the job's PATH. Linux
# amd64 only (GitHub-hosted ubuntu runners). Dependabot can't see these pins:
# bump them by hand, together with the checksum from the release page.
set -euo pipefail

bin_dir="${RUNNER_TEMP:?run this in a GitHub Actions job}/bin"
mkdir -p "$bin_dir"

install_tool() {
  local tool=$1 url sha256 member=""

  case $tool in
    gitleaks) # keep in step with the pre-commit hook
      url="https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz"
      sha256="551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb"
      member="gitleaks"
      ;;
    helm)
      url="https://get.helm.sh/helm-v4.3.1-linux-amd64.tar.gz"
      sha256="0403a88ae20913d11b10a2467b50087721fea7581736da6b9d3992f5357fe54b"
      member="linux-amd64/helm"
      ;;
    hadolint)
      url="https://github.com/hadolint/hadolint/releases/download/v2.15.1/hadolint-linux-x86_64"
      sha256="c7187db94eeeeca956519a6af171adc31453941a1e777961f6e680f697c8c507"
      ;;
    kubeconform)
      url="https://github.com/yannh/kubeconform/releases/download/v0.8.0/kubeconform-linux-amd64.tar.gz"
      sha256="9bc2bffbf71f261128533edaf912153948b7ff238f9a531ae6d34466ec287883"
      member="kubeconform"
      ;;
    yq) # the runner image has a yq too, but not necessarily this version
      url="https://github.com/mikefarah/yq/releases/download/v4.54.1/yq_linux_amd64"
      sha256="8e34fc298390875de416e6a4afcb8cabeceb25d9aa8506c1a2f9353cf702ea5f"
      ;;
    *)
      echo "unknown tool: $tool" >&2
      return 1
      ;;
  esac

  local download
  download=$(mktemp)
  curl -sSfL --retry 3 -o "$download" "$url"
  echo "$sha256  $download" | sha256sum --check --strict --quiet

  if [[ -n $member ]]; then
    tar -xzf "$download" -C "$bin_dir" --strip-components="$(tr -cd / <<<"$member" | wc -c)" "$member"
  else
    install -m 0755 "$download" "$bin_dir/$tool"
  fi
  rm -f "$download"
  echo "installed $tool from $url"
}

for tool in "$@"; do
  install_tool "$tool"
done

echo "$bin_dir" >>"${GITHUB_PATH:?run this in a GitHub Actions job}"
