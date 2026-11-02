# GitHub setup

One-time setup that lets the workflows push images, record releases, and plan and apply
Terraform. Without it the pipelines still run lint, build, scan and validation; the steps
that need AWS, Cloudflare or write access to Git are skipped, not failed.

| What | Kind | Used by | Value |
| --- | --- | --- | --- |
| `AWS_ROLE_ARN` | variable | `app.yaml` (push image) | `infra/envs/shared` output `ecr_push_role_arn` |
| `ECR_REPOSITORY` | variable | `app.yaml` | `infra/envs/shared` output `ecr_repository_url` |
| `ECR_SCAN_ROLE_ARN` | variable | `image-rescan.yaml` (daily scan of running images) | `infra/envs/shared` output `ecr_scan_role_arn` |
| `AWS_REGION` | variable (optional) | all | defaults to `ap-southeast-7` |
| `RELEASE_APP_CLIENT_ID` | variable | `app.yaml` (deploy commit, promote PR) | GitHub App client ID |
| `RELEASE_APP_PRIVATE_KEY` | secret | `app.yaml` | GitHub App private key (PEM) |
| `TF_STATE_BUCKET` | variable | `infra.yaml` | `infra/envs/shared` output `state_bucket_name` |
| `INFRA_PLAN_ROLE_ARN` | variable | `infra.yaml` (plan on pull requests) | `infra/envs/shared` output `infra_plan_role_arn` |
| `CLOUDFLARE_API_TOKEN_READ` | secret | `infra.yaml` (dev/prod plans) | Cloudflare token: Zone Read + DNS Read on the zone |
| `INFRA_APPLY_ENABLED` | variable | `infra.yaml` (apply after merge) | `true` to let merges apply |
| `INFRA_APPLY_ROLE_ARN` | Environment variable (`shared`, `dev`, `prod`) | `infra.yaml` | `infra/envs/shared` output `infra_apply_role_arns[<env>]` |
| `CLOUDFLARE_API_TOKEN` | Environment secret (`dev`, `prod`) | `infra.yaml` | Cloudflare token: Zone Read + DNS Edit on the zone |

There are no AWS keys anywhere: workflows get short-lived credentials through OIDC, and each
IAM role trusts exactly one kind of run (see `infra/modules/github-oidc`).

## 1. AWS variables

After `infra/envs/shared` is applied, copy its outputs into repository variables:

```bash
gh variable set AWS_ROLE_ARN      --body "<ecr_push_role_arn>"
gh variable set ECR_REPOSITORY    --body "<ecr_repository_url>"
gh variable set ECR_SCAN_ROLE_ARN --body "<ecr_scan_role_arn>"
```

Both roles only trust runs on `refs/heads/main`, so pull requests can build and scan but
never push. The scan role can only pull: the daily rescan reads the images dev and prod run
and keeps a `vulnerability` issue per environment up to date.

## 2. Release GitHub App

CI deploys by committing to Git: the new image tag goes into
`k8s/charts/web/values-dev.yaml` on `main`, and a pull request proposes the same tag for
prod. Those writes use a GitHub App rather than the alternatives:

| Option | Why not |
| --- | --- |
| `GITHUB_TOKEN` | Commits and pull requests it creates don't trigger workflows, so the manifest checks would never run on release commits or on the promote PR. Letting it past the branch ruleset would let every workflow past. |
| Personal access token | Belongs to a person, is long-lived, and leaves with them. Commits look like that person's. |
| Deploy key | SSH push only: it can't open pull requests, and its commits aren't attributed. |
| **GitHub App** | Installed on this one repository with only the permissions below. Each job gets a one-hour token, narrowed further per job and revoked when the job ends. Commits are attributed to the App's bot user, it can be the single bypass actor on the `main` ruleset, and its pushes and pull requests trigger workflows normally. |

Create it (Settings → Developer settings → GitHub Apps → New GitHub App):

1. **Name:** anything unique, for example `<owner>-messagespring-release`.
   **Homepage URL:** the repository URL.
2. **Webhook:** untick *Active*. The App never receives events; workflows call it.
3. **Repository permissions:**
   - Contents: **Read and write** (commit the dev tag, push the promote branch)
   - Pull requests: **Read and write** (open and update the promote PR, set its assignee
     and `release` label)
   - Metadata: Read-only (always on)
   - Nothing else. It doesn't need Workflows permission: it never edits `.github/`.
4. **Where can this GitHub App be installed:** Only on this account.
5. Create the App, then note its **Client ID** and **Generate a private key** (downloads a
   `.pem` file).
6. **Install App** → Only select repositories → this repository.
7. Store the credentials, then delete the downloaded key (or keep it only in a password
   manager):

   ```bash
   gh variable set RELEASE_APP_CLIENT_ID --body "<client id>"
   gh secret set RELEASE_APP_PRIVATE_KEY < ~/Downloads/<app-name>.<date>.private-key.pem
   rm ~/Downloads/<app-name>.<date>.private-key.pem
   ```

To rotate the key: generate a new one, update the secret, then delete the old key in the
App's settings. To cut CI off from Git completely, suspend or uninstall the App.

## 3. Infrastructure pipeline

`infra.yaml` checks every infrastructure change (fmt, validate, tflint, Trivy) without any
credentials. With the setup below it also posts a plan per environment on each pull request
and applies after merge.

**Plans on pull requests** use a read-only role that only trusts `pull_request` runs:

```bash
gh variable set TF_STATE_BUCKET     --body "<state_bucket_name>"
gh variable set INFRA_PLAN_ROLE_ARN --body "<infra_plan_role_arn>"
gh secret set CLOUDFLARE_API_TOKEN_READ     # paste a Zone Read + DNS Read token
```

Cloudflare has no OIDC federation, so its tokens are the only stored credentials: a
read-only one for plans, and an edit token that only the `dev` and `prod` Environments can
use. dev and prod are planned and applied only once their `terraform.tfvars` hold real
values instead of the placeholder domain and admin CIDR. Plans don't run for forks or
Dependabot, which get no OIDC token or secrets; plan a Dependabot Terraform update locally
before merging it.

**Applies after merge** run shared, then dev, then prod, one at a time, each in its GitHub
Environment. Each apply role trusts only jobs running in its Environment.

1. Settings → Environments → create `shared`, `dev` and `prod`. For each:
   - **Deployment branches:** Selected branches → `main`.
   - `prod` (and `shared`, which holds the CI roles): **Required reviewers** → yourself.
     In a one-person repository, untick *Prevent self-review*.
2. Add the apply role and the Cloudflare edit token:

   ```bash
   for env in shared dev prod; do
     gh variable set INFRA_APPLY_ROLE_ARN --env "$env" --body "<infra_apply_role_arns[$env]>"
   done
   gh secret set CLOUDFLARE_API_TOKEN --env dev    # Zone Read + DNS Edit
   gh secret set CLOUDFLARE_API_TOKEN --env prod
   ```

3. Turn applies on: `gh variable set INFRA_APPLY_ENABLED --body true`.

Environments on private repositories need a paid plan; on GitHub Free they work once the
repository is public. Until then, apply by hand from a laptop (see
[cluster-bootstrap.md](cluster-bootstrap.md)). `infra/bootstrap` and
`infra/envs/<env>/bootstrap` are always applied by hand.

## 4. Default workflow token

Settings → Actions → General → Workflow permissions:

- **Read repository contents and packages permissions** (the default `GITHUB_TOKEN` is
  read-only; each job asks for more in its `permissions:` block).
- Leave **Allow GitHub Actions to create and approve pull requests** unticked: the App opens
  the promote PR, and nothing should approve pull requests automatically.

## 5. Branch protection (`main` ruleset)

Settings → Rules → Rulesets → New branch ruleset, target `main`:

- **Restrict deletions** and **Block force pushes**
- **Require linear history** (merge with *Rebase and merge*, so every commit is kept)
- **Require a pull request before merging**, 0 approvals (one maintainer)
- **Require status checks to pass:**

  | Check | Workflow |
  | --- | --- |
  | `pre-commit` | `pre-commit.yaml` |
  | `gitleaks (full history)` | `secret-scan.yaml` |
  | `app ok` | `app.yaml` |
  | `infra ok` | `infra.yaml` |
  | `k8s ok` | `k8s.yaml` |

- **Bypass list:** only the release GitHub App, so its commit to `values-dev.yaml` can go
  straight to `main`. That commit is still validated by `k8s.yaml` on `main`, and the
  promote PR for prod goes through every check above.

A required check that never reports blocks a pull request forever, so workflows with path
filters can't be required as they are. `app`, `infra` and `k8s` therefore run on every pull
request, skip their jobs when their paths didn't change, and end with an `… ok` job that
always reports. It fails only if a job it depends on failed or was cancelled.

Rulesets on private repositories need a paid plan; on GitHub Free they take effect once the
repository is public.
