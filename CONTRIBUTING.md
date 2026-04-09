# Contributing and version control

This document supports the **DevOps / Git** workflow for **PeEx-tasks**: branching, commits, releases, and safe handling of secrets alongside **Terraform** in `infra/azure/terraform/`.

## Directory layout (IaC and app)

| Path | Role |
|------|------|
| `app_web.py`, `app.py` | Flask application |
| `templates/` | Web UI |
| `tests/` | Pytest |
| `Dockerfile`, `requirements.txt` | Container image |
| `.github/workflows/` | CI/CD (validate, GHCR, deploy to Azure VM) |
| `infra/azure/terraform/` | Terraform: VNet, VM, storage, NSG (`*.tf`, `templates/`) |
| `infra/azure/README.md` | Azure deploy/destroy, variables, troubleshooting |

Layout follows **separation by function**: application code at the root, **infrastructure by cloud provider** under `infra/azure/`, automation under `.github/`. This stays modular without nesting unrelated tools.

## Branching strategy

- **`main`** — protected, **stable** integration branch. Direct pushes are typically blocked by repository rules; changes land via **Pull Request**.
- **`feature/<short-name>`** (or `fix/`, `docs/`) — short-lived branches from latest `main` for one logical change.
- **Pull requests** — required to merge into `main`; CI (**Validate, Lint and Test**) must pass before merge.

Flow: `git checkout main && git pull` → `git checkout -b feature/my-change` → commit → push → open PR → review → merge.

## Commit messages (conventional style)

Use a **type** prefix and imperative, concise description:

| Type | Use for |
|------|---------|
| `feat:` | New user-facing behavior |
| `fix:` | Bug fix |
| `docs:` | Documentation only |
| `infra:` | Terraform / cloud resources |
| `ci:` | GitHub Actions / pipeline |
| `chore:` | Maintenance, deps, tooling |
| `test:` | Tests only |

Examples:

- `feat: increase medium/high load intensity`
- `infra: add Azure storage access_tier variable`
- `docs: document GHCR deploy secrets`
- `ci: deploy to Azure VM via SSH`

**Task requirement:** keep history **auditable** — one commit per logical unit when possible; avoid noisy “WIP” commits on `main` (squash on merge if your team prefers).

## Releases and semantic versioning

**Tags** use **SemVer**: `vMAJOR.MINOR.PATCH` (e.g. `v1.0.0`).

- **MAJOR** — incompatible API/behavior changes.
- **MINOR** — backward-compatible additions.
- **PATCH** — fixes, small safe changes.

Create an **annotated** tag after a stable merge to `main`:

```bash
git checkout main
git pull origin main
git tag -a v1.0.0 -m "chore(release): v1.0.0 stable baseline (app + Azure IaC + CI)"
git push origin v1.0.0
```

List tags: `git tag -l 'v*'`. In GitHub: **Releases** can be created from a tag for notes and artifacts.

## Secrets and files never committed

Do **not** commit:

- `terraform.tfvars` (contains `ssh_public_key` and local overrides)
- `terraform.tfstate` / `*.tfstate.*`
- `.terraform/` (provider cache)
- `tfplan` / `*.tfplan`
- Private SSH keys, PEM files, `.env` with credentials
- GitHub **environment** secrets belong in **Settings → Environments**, not in the repo

Use `terraform.tfvars.example` as a template; real values stay local or in secret stores.

## Clone and use (another contributor)

```bash
git clone https://github.com/<org>/PeEx-tasks.git
cd PeEx-tasks
# Application
python -m venv .venv && source .venv/bin/activate  # or Windows equivalent
pip install -r requirements.txt
PYTHONPATH=. pytest -v

# Terraform (Azure)
cd infra/azure/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set ssh_public_key, etc.
az login
terraform init
terraform plan
terraform apply
```

No repo edits are required beyond copying `terraform.tfvars.example` → `terraform.tfvars` and Azure login.

## Pull request checklist

- [ ] Branch is up to date with `main` (rebase or merge).
- [ ] Lint/tests pass locally (`flake8`, `pytest`, `docker build` if you touch the image).
- [ ] No secrets or state files in the diff.
- [ ] Commit messages follow the convention above.
- [ ] README / `infra/azure/README.md` updated if behavior or variables change.
