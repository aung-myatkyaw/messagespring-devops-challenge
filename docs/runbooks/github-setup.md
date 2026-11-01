# GitHub setup

One-time setup that lets the workflows push images and record releases. Without it the
pipelines still run lint, build, scan and validation; the steps that need AWS or write to
Git are skipped.

| What | Kind | Used by | Value |
| --- | --- | --- | --- |
| `AWS_ROLE_ARN` | variable | `app.yaml` (push image) | `infra/envs/shared` output `ecr_push_role_arn` |
| `ECR_REPOSITORY` | variable | `app.yaml` | `infra/envs/shared` output `ecr_repository_url` |
| `ECR_SCAN_ROLE_ARN` | variable | `image-rescan.yaml` (daily scan of running images) | `infra/envs/shared` output `ecr_scan_role_arn` |
| `AWS_REGION` | variable (optional) | all | defaults to `ap-southeast-7` |
| `RELEASE_APP_CLIENT_ID` | variable | `app.yaml` (deploy commit, promote PR) | GitHub App client ID |
| `RELEASE_APP_PRIVATE_KEY` | secret | `app.yaml` | GitHub App private key (PEM) |

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

## 3. Default workflow token

Settings → Actions → General → Workflow permissions:

- **Read repository contents and packages permissions** (the default `GITHUB_TOKEN` is
  read-only; each job asks for more in its `permissions:` block).
- Leave **Allow GitHub Actions to create and approve pull requests** unticked: the App opens
  the promote PR, and nothing should approve pull requests automatically.

## 4. Branch protection

See the `main` ruleset in the README. The release App is its only bypass actor, so its
commit to `values-dev.yaml` can go straight to `main` while every other change needs a pull
request with passing checks. Rulesets on private repositories need a paid plan; on GitHub
Free they take effect once the repository is public.
