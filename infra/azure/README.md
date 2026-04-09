# Azure infrastructure (Terraform)

This folder defines a minimal **Microsoft Azure** environment for the **PeEx-tasks** app: resource group, VNet + subnet, NSG (SSH + app port), Ubuntu 22.04 VM with public IP, managed OS disk, and a storage account with a **private** blob container. **cloud-init** installs **Docker** on first boot so you can run the Flask app from a container (manually or via GitHub Actions).

**Related docs:** repository root [`README.md`](../../README.md), [`CONTRIBUTING.md`](../../CONTRIBUTING.md).

---

## Terraform directory layout

All IaC for this stack lives under `infra/azure/terraform/`:

| File / path | Purpose |
|-------------|---------|
| `versions.tf` | Terraform and provider version constraints |
| `providers.tf` | `azurerm` provider block |
| `main.tf` | Resource group, shared tags (`local.common_tags`) |
| `networking.tf` | VNet, subnet, NSG + rules, public IP, NIC |
| `compute.tf` | Linux VM, SSH key, optional `custom_data` from cloud-init |
| `storage.tf` | Storage account (unique name suffix), blob container `appdata` |
| `variables.tf` | Input variables (region, sizing, network, security, storage) |
| `outputs.tf` | IPs, IDs, SSH hint, app URL, storage names |
| `templates/cloud-init.yaml.tpl` | Docker + git on first boot (when `enable_docker_cloud_init = true`) |
| `terraform.tfvars.example` | Safe template — copy to `terraform.tfvars` (not committed) |
| `backend.tf.example` | Optional remote state — copy to `backend.tf` if needed |
| `.terraform.lock.hcl` | **Commit this** — pins provider versions for reproducible `init` |

Do **not** commit: `terraform.tfstate`, `*.tfstate.*`, `terraform.tfvars`, `tfplan`, `.terraform/`.

### Layout, modularity, and Terraform best practices

This stack follows common **root-module** conventions recommended for Terraform:

| Practice | How it is applied here |
|----------|-------------------------|
| **Separation by concern** | Networking (`networking.tf`), compute (`compute.tf`), and storage (`storage.tf`) are isolated so each file maps to one domain; changes stay localized and reviews are easier. |
| **Configurable inputs** | All tunable values (region, sizing, CIDRs, NSG sources, storage tiers) live in `variables.tf`, not hard-coded in resources. |
| **Explicit outputs** | `outputs.tf` exposes connection and resource identifiers for operators, scripts, and documentation—no need to read state by hand. |
| **Provider and version pinning** | `versions.tf` and committed `.terraform.lock.hcl` keep provider versions reproducible across machines and CI. |
| **Secrets outside VCS** | Real values use `terraform.tfvars` (ignored) or environment variables; `terraform.tfvars.example` documents shape without secrets. |
| **External templates** | `templates/cloud-init.yaml.tpl` keeps VM bootstrap logic out of long HCL strings and allows `templatefile()` reuse. |
| **Optional remote state** | `backend.tf.example` documents moving state to shared storage for teams without forcing it on solo use. |

**Modularity** here is implemented as a **single root module split into logical `.tf` files** (HashiCorp’s usual pattern for small/medium stacks). That satisfies “modular and organized” for coursework and many production repos. **Nested `module` blocks** (e.g. `modules/network`) become worthwhile when you reuse the same block across environments or repositories; this project stays readable without that extra layer until duplication appears.

---

## Architecture

```mermaid
flowchart TB
  subgraph Internet
    User[User / browser / CI]
  end

  subgraph rg["Resource group"]
    subgraph vnet["Virtual network"]
      subgraph snet["Subnet + NSG"]
        PIP[Public IP]
        NIC[Network interface]
        VM[Ubuntu VM + Docker]
      end
    end
    STG[Storage account]
    BLOB[Blob container appdata]
  end

  User -->|SSH :22| PIP
  User -->|HTTP :5000| PIP
  PIP --> NIC --> VM
  STG --> BLOB
  VM -. optional artifacts .-> BLOB
```

- **Network:** one VNet (`address_space`, default `10.42.0.0/16`) and one subnet (`10.42.1.0/24`).
- **Security:** NSG on the subnet — inbound TCP **22** (SSH) and **5000** (app). Source CIDRs are variables (`admin_source_address_prefix`, `app_source_address_prefix`); tighten for production.
- **Compute:** one Linux VM (`Standard_B2s` by default), system-assigned managed identity, **SSH public key only** (no password).
- **Storage:** GPv2-style account (`account_tier` Standard/Premium, `access_tier` Hot/Cool for Standard), private container `appdata`, TLS 1.2, HTTPS-only, blob soft delete.

---

## Prerequisites

- Azure subscription and rights to create resource groups and resources.
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli): `az login`, then `az account set --subscription "<id-or-name>"`.
- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.5`.
- **RSA** SSH public key (`ssh-rsa ...`). Azure does **not** use Ed25519 for `admin_ssh_key` on this VM resource. Example:  
  `ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_azure`

---

## Configuration (no secrets in Git)

```bash
cd infra/azure/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` — at minimum set `ssh_public_key` to one line from your `*.pub` file.

**Without a tfvars file** (Linux/macOS):

```bash
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_rsa_azure.pub)"
```

**Windows PowerShell:**

```powershell
$env:TF_VAR_ssh_public_key = Get-Content $env:USERPROFILE\.ssh\id_rsa_azure.pub -Raw
```

Review `variables.tf` for region, VM size, CIDRs, NSG sources, `app_port`, storage options.

---

## Deploy

From `infra/azure/terraform`:

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Or:

```bash
terraform apply -auto-approve
```

After apply:

```bash
terraform output
terraform output -raw vm_public_ip
```

Open the UI after the container runs: `http://<vm_public_ip>:5000` (see below or use CI).

---

## Destroy

```bash
terraform destroy -auto-approve
```

Or: `terraform plan -destroy -out=destroy.tfplan` then `terraform apply destroy.tfplan`.  
Confirm subscription and resource group before destroying.

---

## SSH to the VM

Use the **private** key that matches the **public** key in `terraform.tfvars`:

```bash
chmod 600 ~/.ssh/id_rsa_azure
ssh -i ~/.ssh/id_rsa_azure azureuser@$(terraform output -raw vm_public_ip)
```

If `docker` fails with permission errors, use `sudo docker` or re-login after cloud-init adds `azureuser` to the `docker` group.

### Manual app on the VM (without CI)

```bash
git clone https://github.com/<your-org>/PeEx-tasks.git
cd PeEx-tasks
docker build -t peex-app .
docker run -d --name peex-app -p 5000:5000 peex-app
```

---

## CI/CD: GitHub Actions → Azure VM

Workflow: [`.github/workflows/cicd.yml`](../../.github/workflows/cicd.yml).

On **push to `main`** (after merge, if `main` is branch-protected): build → push image to **GHCR** at `ghcr.io/<owner>/<repo>` (lowercase) → SSH to VM → `docker pull` → run container **`peex-app`** on port **5000** → smoke test `/health`.

### Repository settings

1. **Branch protection:** changes usually go through **feature branches** (e.g. `feature/azure-infra-ci`) and **Pull Request** into `main`; required check **Validate, Lint and Test** must pass before merge.
2. **Environment `azure`:** **Settings → Environments → New environment** → name **`azure`**.
3. **Environment secrets** (for jobs that use `environment: azure`):

   | Secret | Description |
   |--------|-------------|
   | `AZURE_VM_HOST` | Public IP of the VM (`terraform output -raw vm_public_ip`). |
   | `AZURE_SSH_PRIVATE_KEY` | Full **private** RSA key (multiline PEM / OpenSSH), matching the public key on the VM. |
   | `GHCR_READ_TOKEN` | Optional PAT with `read:packages` if `docker pull` on the VM fails with auth errors. |

4. The deploy script uses **`sudo docker`**. Cloud-init should leave Docker running; the private key in GitHub must parse correctly (see troubleshooting).

---

## Configurable variables (summary)

| Variable | Purpose |
|----------|---------|
| `location` | Azure region |
| `name_prefix` | Resource name prefix (validated format) |
| `environment`, `project_name`, `repository_label`, `cost_center` | Tags |
| `address_space`, `subnet_prefixes` | VNet / subnet CIDRs |
| `vm_size`, `os_disk_size_gb` | VM SKU and OS disk |
| `ssh_public_key` | **Required** RSA public key for `admin_username` |
| `admin_username` | Linux admin user (default `azureuser`) |
| `admin_source_address_prefix`, `app_source_address_prefix` | NSG source for SSH / app port |
| `app_port` | Exposed app port (default `5000`) |
| `enable_docker_cloud_init` | Install Docker via cloud-init |
| `storage_account_tier`, `storage_access_tier`, `storage_replication_type` | Storage account options |

Details and defaults: `variables.tf`.

---

## Outputs

`vm_public_ip`, `vm_private_ip`, `ssh_command`, `app_url`, `storage_account_name`, `storage_container_name`, `virtual_network_id`, `resource_group_name`, etc. — see `outputs.tf`.

---

## Remote state (optional)

Copy `backend.tf.example` to `backend.tf`, provision a storage account + container for state, then `terraform init -migrate-state`. Do not commit secrets in `backend.tf`.

---

## Troubleshooting

| Issue | What to do |
|-------|------------|
| **Ed25519 not supported** | Use RSA: `ssh-keygen -t rsa -b 4096`; put `ssh-rsa ...` in `terraform.tfvars`. |
| **`account_tier` vs Hot/Cool** | `account_tier` = `Standard` or `Premium`; Hot/Cool = `storage_access_tier` (see `storage.tf`). |
| **Azure auth errors** | `az login`, correct `az account set`. |
| **`ssh_public_key` unset** | `terraform.tfvars` or `TF_VAR_ssh_public_key`. |
| **`ssh.ParsePrivateKey: no key found` in CI** | `AZURE_SSH_PRIVATE_KEY` must be the **full private** key with newlines, not the `.pub` file; avoid passphrase-protected keys for Actions unless you use a different approach. |
| **App URL does not load** | Container must publish `-p 5000:5000`; NSG must allow your client if you restricted `app_source_address_prefix`. |
| **Storage account name taken** | Change `name_prefix` or re-apply (random suffix helps). |
| **VM planned for replacement** | Changing `custom_data` forces replacement; avoid casual edits after first deploy. |
| **Slow `terraform plan`** | First run or API refresh; try `TF_LOG=INFO`; check network/VPN. |

---

## IaC acceptance checklist (course mapping)

- [x] VNet + subnet — `networking.tf`
- [x] Compute — `compute.tf`
- [x] Storage — `storage.tf`
- [x] NSG — `networking.tf`
- [x] Create / destroy — `terraform apply` / `terraform destroy`
- [x] Variables — `variables.tf`
- [x] Modular `*.tf` files
- [x] Outputs — `outputs.tf`
- [x] Resource tags — `local.common_tags`
- [x] No secrets in repo — `terraform.tfvars` gitignored; example file only

For submissions, capture **terminal or screenshots** of `terraform plan`, `terraform apply`, resources in Azure Portal, `terraform output`, and (if required) `terraform destroy`.
