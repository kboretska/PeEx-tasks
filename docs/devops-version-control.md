# DevOps: version control (assignment checklist)

This note maps the **“Store and manage infrastructure configuration in VCS”** task to this repository. Authoritative policies live in **`CONTRIBUTING.md`** and **`README.md`**.

## Artifacts to attach in your report

| Artifact | How to produce |
|----------|----------------|
| Repository URL | `https://github.com/<owner>/PeEx-tasks` |
| Directory tree screenshot | GitHub **Code** view or `tree -L 3` locally |
| Git log with descriptive commits | `git log --oneline -10` (screenshot) |
| Tagged release | **Releases** page or `git tag -l` + `git show v1.0.0` |
| `.gitignore` | Open `.gitignore` in repo (IaC + secrets exclusions) |
| Clone + use | Commands below |

## Example: clone and run Terraform (peer handoff)

```bash
git clone https://github.com/<owner>/PeEx-tasks.git
cd PeEx-tasks/infra/azure/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars (RSA ssh_public_key, optional overrides)
az login
terraform init
terraform plan
# terraform apply   # when ready
```

No other repository changes are required for a second developer beyond local `terraform.tfvars` and Azure login.

## Release tag (semantic versioning)

After stable code is on `main`:

```bash
git checkout main
git pull origin main
git tag -a v1.0.0 -m "chore(release): v1.0.0"
git push origin v1.0.0
```

## Task criteria (quick map)

- **Structure** — `infra/azure/terraform/`, `.github/workflows/`, app at root (`README.md` table).
- **`.gitignore`** — Terraform state/plan, `*.tfvars`, `.terraform/`, plus key/credential patterns.
- **≥3 meaningful commits** — use `git log`; continue with conventional messages (`CONTRIBUTING.md`).
- **Tag `v*.*.*`** — e.g. `v1.0.0` (see above).
- **README** — root `README.md` + `CONTRIBUTING.md` + `infra/azure/README.md`.
- **No secrets in Git** — never commit `terraform.tfvars`, `*.tfstate`, private keys.
- **Branches** — feature branches + PR into `main` (`CONTRIBUTING.md`).
