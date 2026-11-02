# Cluster bootstrap

Builds an environment from nothing: the state bucket, the account-wide
resources, one environment's AWS infrastructure, and Argo CD, which then
deploys everything else from Git. It also covers taking an environment down.

Run it from a laptop with an administrator session. After the first run, the
infrastructure pipeline applies changes on merge
([github-setup.md §3](github-setup.md#3-infrastructure-pipeline)); the two
bootstrap layers are always run by hand.

The commands use `dev`; for prod, replace `dev` with `prod` everywhere.

## 0. Before you start

**Tools:** Terraform ≥ 1.11 (or OpenTofu), AWS CLI v2, `kubectl`, `gh`.

**Account, once:**

- Enable the opt-in region `ap-southeast-7` (Account → AWS Regions).
- Sign in through IAM Identity Center. The cluster admin is the Identity
  Center role of the permission set named in `admin_sso_permission_set`
  (default `AdministratorAccess`). Without Identity Center, set it to `null`
  and list admin roles in `extra_admin_principal_arns`.
- Create the Spot service-linked role, or Karpenter can't launch Spot nodes in
  dev (an error saying it already exists is fine):

  ```bash
  aws iam create-service-linked-role --aws-service-name spot.amazonaws.com
  ```

**Cloudflare:** an existing zone and two API tokens, each limited to that
zone:

| Token | Permissions | Used by |
| --- | --- | --- |
| Terraform | Zone Read, DNS Edit | `CLOUDFLARE_API_TOKEN` in your shell (and the `dev`/`prod` GitHub Environments) |
| external-dns | Zone Read, DNS Edit | Parameter Store, step 4 |

If the zone has CAA records, one must allow `amazon.com`, or ACM can't issue
the certificate.

**Real values in Git** (the committed files hold placeholders):

1. In `infra/envs/dev/terraform.tfvars`, set `cloudflare_zone_name`,
   `app_hostname` and `endpoint_public_access_cidrs` (your admin IP, `/32`).
2. Write the account-specific Kubernetes values, with the same hostname:

   ```bash
   scripts/set-env-values.sh dev <aws-account-id> <zone> [hostname]
   ```

3. Review the diff and merge it through a pull request. Argo CD deploys from
   `main`, so these must be there before step 5.

**Shell, for every Terraform session.** Credentials come from the
environment, never from files in the repository:

```bash
aws sso login --profile <admin-profile>
export AWS_PROFILE=<admin-profile>
read -rs "CLOUDFLARE_API_TOKEN?Cloudflare token: " && export CLOUDFLARE_API_TOKEN   # zsh; bash: read -rsp
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
STATE_BUCKET="messagespring-tfstate-${ACCOUNT_ID}-ap-southeast-7"
```

## 1. State bucket (once per account)

```bash
cd infra/bootstrap
terraform init
terraform apply
```

This root keeps **local state** (it creates the bucket the others use). The
`terraform.tfstate` file is git-ignored: keep a copy somewhere safe, such as a
password manager. If it's lost, see
[backup-restore.md](backup-restore.md#bootstrap-state).

## 2. Account-wide resources (once per account)

```bash
cd infra/envs/shared
terraform init -backend-config="bucket=${STATE_BUCKET}"
terraform apply
```

Creates the ECR repository, the GitHub OIDC provider and the CI roles. Then
configure GitHub with its outputs: [github-setup.md](github-setup.md).

If the apply fails with `EntityAlreadyExists` on the OIDC provider, the account
already has one for GitHub (only one per URL is allowed). Import it instead of
creating it:

```bash
terraform import module.github_oidc.aws_iam_openid_connect_provider.github \
  "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
```

## 3. The environment (about 20 minutes)

```bash
cd infra/envs/dev
terraform init -backend-config="bucket=${STATE_BUCKET}"
terraform plan -out=tfplan
terraform apply tfplan
```

Most of the time goes to the EKS control plane and the certificate validation.
Check access to the cluster:

```bash
aws eks update-kubeconfig --region ap-southeast-7 --name messagespring-dev
kubectl get nodes        # one system node (two in prod)
```

## 4. The external-dns token

Terraform created the parameter with a placeholder, so the token never enters
Terraform state. Write the real token **before step 5**: external-dns is wave
-3, and the app (wave 10) isn't created until it's healthy.

```bash
read -rs "CF_TOKEN?external-dns token: "
aws ssm put-parameter --overwrite --type SecureString \
  --key-id alias/messagespring-dev-secrets \
  --name /messagespring/dev/external-dns/cloudflare-api-token \
  --value "$CF_TOKEN"
unset CF_TOKEN
```

## 5. Argo CD

**While the repository is private,** Argo CD needs read access. Create a
fine-grained GitHub token with read-only *Contents* on this repository only,
and store it as an Argo CD repository Secret before installing Argo CD (the
Helm install accepts the existing namespace):

```bash
kubectl create namespace argocd
read -rs "GH_TOKEN?read-only GitHub token: "
kubectl -n argocd create secret generic repo-messagespring \
  --from-literal=type=git \
  --from-literal=url=https://github.com/aung-myatkyaw/messagespring-devops-challenge.git \
  --from-literal=username=git \
  --from-literal=password="$GH_TOKEN"
kubectl -n argocd label secret repo-messagespring argocd.argoproj.io/secret-type=repository
unset GH_TOKEN
```

Delete the Secret and the token once the repository is public.

**Install Argo CD and the root Application:**

```bash
cd infra/envs/dev/bootstrap
terraform init -backend-config="bucket=${STATE_BUCKET}"
terraform apply
```

From here Argo CD syncs everything in `k8s/argocd/envs/dev/` in wave order,
including itself. It takes about 10 minutes, mostly waiting for Karpenter's
first node and the load balancer.

## 6. Check

```bash
kubectl -n argocd get applications     # all Synced and Healthy; web last
kubectl get nodeclaims                 # a Karpenter node for the web pods (Spot in dev)
kubectl -n web get pods,ingress
curl -fsS https://<hostname>/api/health
```

- **Argo CD UI:** `kubectl -n argocd port-forward svc/argocd-server 8080:443`,
  then <https://localhost:8080>, user `admin`. The first password is in the
  `argocd-initial-admin-secret` Secret; change it, then delete that Secret.
- **Grafana:** `kubectl -n logging port-forward svc/grafana 3000:80`, then
  <http://localhost:3000>, user `admin`, password from Parameter Store
  (`/messagespring/dev/grafana/admin-password`). Logs are under Explore → Loki.

**If a wave is stuck:**

| Symptom | Likely cause |
| --- | --- |
| `external-dns` Degraded, `web` never created | the token in step 4 is still the placeholder, or lacks DNS Edit |
| `web` Progressing, pods Pending | Karpenter can't launch nodes: the Spot service-linked role (step 0) or the NodePool limits |
| Ingress has no address | load balancer controller logs; the public subnets need the `kubernetes.io/role/elb` tag (set by Terraform) |
| Certificate not found | `app_hostname` in tfvars differs from `ingress.host` in `values-dev.yaml` |
| Applications show `ComparisonError` | the repository Secret (private repository) |

## 7. Taking an environment down

Order matters: the controllers created AWS and Cloudflare resources that
Terraform doesn't know about. Delete them through Kubernetes first, or they
are orphaned and keep costing money.

1. Delete the `web` Application, then the `karpenter-nodes` Application, while
   Karpenter still runs, so it terminates its nodes. Wait until
   `kubectl get nodeclaims` is empty.
2. Check that the ALB and target groups are gone (load balancer controller)
   and the DNS record is removed (external-dns). Delete the PVCs so their EBS
   volumes go.
3. `terraform destroy` in `infra/envs/dev/bootstrap`, then `infra/envs/dev`.
   prod has deletion protection; turn it off in tfvars first, deliberately.
4. Only when removing everything: empty the ECR repository, destroy
   `infra/envs/shared`, then `infra/bootstrap` (its bucket has
   `prevent_destroy` and is versioned: remove the guard locally, empty all
   versions, then destroy).

KMS keys wait 7–30 days before deletion; that's expected, and the deletion
can be cancelled in that window.
