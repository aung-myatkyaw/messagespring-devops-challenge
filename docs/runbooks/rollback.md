# Rollback

Everything in the clusters comes from Git, so a rollback is a revert in Git.
Argo CD then syncs the previous state. Don't roll back in the Argo CD UI or
with `kubectl`: self-heal puts Git's version back within minutes, which is
intended.

The `main` ruleset requires a pull request for every change, so a revert is a
small pull request; its checks take a few minutes.

## Application

Every release is one commit that changes the image in a values file:

| Environment | Release commit | Made by |
| --- | --- | --- |
| dev | `chore(release): deploy web <sha> to dev` | the release GitHub App, on every build of `main` |
| prod | `chore(release): promote web <sha> to prod` | merging the promote pull request |

**Roll back prod:**

```bash
git switch main && git pull --ff-only
git log --oneline -- k8s/charts/web/values-prod.yaml     # find the bad release commit
git switch -c revert/prod-<sha>
git revert <release-commit>
git push -u origin HEAD
gh pr create --fill --label release
```

Merge it once the checks pass. Argo CD deploys the previous image, which is
still in ECR (the newest 50 images are kept). Watch it:

```bash
kubectl -n argocd get application web -w        # Synced, then Healthy
kubectl -n web rollout status deployment/web
```

The rolling update replaces pods one at a time, and each new pod takes traffic
only after the ALB reports it healthy, so a rollback causes no downtime.

**Roll back dev** the same way, with `values-dev.yaml`.

**Stop it coming back.** The bad code is still on `main`, so the next build
deploys it to dev again, and the promote pull request offers it for prod.
Revert or fix the code change too, and close or update the promote pull
request until the fix is in.

**Go back further than one release:** set `image.tag` in the values file to
any earlier tag that's still in ECR (`git log` of the values file lists them),
in a pull request.

## Platform add-ons

An add-on (Argo CD, Karpenter, the load balancer controller, Loki and so on)
changes when its chart version or values change in Git. Revert that commit in
a pull request, as above.

Check the chart's release notes first: some upgrades change CRDs or stored
data in ways an older version can't read (Karpenter's CRDs, Loki's schema).
Then a fix forward is safer than a rollback.

**If Argo CD itself is broken** and can't sync its own rollback, apply the
previous chart version by hand with the same values, from an admin session:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm upgrade argocd argo/argo-cd --version <previous-version> -n argocd \
  -f k8s/platform/argo-cd/values.yaml -f k8s/platform/argo-cd/values-dev.yaml
```

Then merge the revert in Git, so self-heal doesn't upgrade it again.

## Infrastructure

Terraform changes are rolled back by reverting the commit in a pull request:
the plan comment shows what the revert changes, and the merge applies it.

Some changes can't simply be reversed:

- **Destroyed resources** come back empty (a deleted bucket loses its objects;
  a replaced cluster loses everything Argo CD doesn't re-create). Check the
  plan for `destroy` and `replace` before merging the original change.
- **Kubernetes version upgrades** can't be downgraded. Test them in dev first;
  for prod, that's the reason dev exists.
- **A corrupted or wrong state file:** restore an earlier version, see
  [backup-restore.md](backup-restore.md#terraform-state).
