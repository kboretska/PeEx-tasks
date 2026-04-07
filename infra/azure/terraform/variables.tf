variable "name_prefix" {
  description = "Prefix for resource names (letters, numbers, hyphens)."
  type        = string
  default     = "peex-tasks"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,30}[a-z0-9]$", var.name_prefix))
    error_message = "name_prefix must be 3-32 chars, lowercase alphanumeric with hyphens."
  }
}

variable "location" {
  description = "Azure region for all resources (e.g. westeurope, eastus)."
  type        = string
  default     = "westeurope"
}

variable "environment" {
  description = "Environment label used in tags (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name tag for cost and governance."
  type        = string
  default     = "PeEx-tasks"
}

variable "repository_label" {
  description = "Repository or workload identifier tag."
  type        = string
  default     = "PeEx-tasks"
}

variable "cost_center" {
  description = "Optional cost center tag (use empty string if not needed)."
  type        = string
  default     = "unassigned"
}

variable "address_space" {
  description = "Address space for the virtual network."
  type        = list(string)
  default     = ["10.42.0.0/16"]
}

variable "subnet_prefixes" {
  description = "CIDR blocks for subnets (first subnet hosts the VM)."
  type        = list(string)
  default     = ["10.42.1.0/24"]
}

variable "admin_username" {
  description = "Linux admin username on the VM."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "RSA public key for VM access (Azure requires ssh-rsa for Linux VMs). Ed25519 is not supported. Generate: ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^ssh-rsa\\s+", var.ssh_public_key))
    error_message = "Azure Linux VMs only accept RSA keys (must start with 'ssh-rsa'). Use: ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa"
  }
}

variable "vm_size" {
  description = "Azure VM SKU (e.g. Standard_B2s, Standard_B1s for smaller cost)."
  type        = string
  default     = "Standard_B2s"
}

variable "os_disk_size_gb" {
  description = "OS managed disk size in GB."
  type        = number
  default     = 30
}

variable "admin_source_address_prefix" {
  description = "CIDR allowed to SSH (port 22). Restrict to your IP/32 in production. Use '*' only for labs."
  type        = string
  default     = "*"
}

variable "app_port" {
  description = "TCP port for the Flask app (matches Dockerfile EXPOSE)."
  type        = number
  default     = 5000
}

variable "app_source_address_prefix" {
  description = "CIDR allowed to reach the app port on the VM."
  type        = string
  default     = "*"
}

variable "enable_docker_cloud_init" {
  description = "If true, cloud-init installs Docker on first boot for running the containerized app."
  type        = bool
  default     = true
}

variable "storage_account_tier" {
  description = "Storage account performance tier: Standard (GPv2) or Premium."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "storage_account_tier must be Standard or Premium."
  }
}

variable "storage_access_tier" {
  description = "Blob access tier for Standard accounts (Hot vs Cool pricing)."
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.storage_access_tier)
    error_message = "storage_access_tier must be Hot or Cool."
  }
}

variable "storage_replication_type" {
  description = "Replication for the storage account (LRS, GRS, etc.)."
  type        = string
  default     = "LRS"
}
