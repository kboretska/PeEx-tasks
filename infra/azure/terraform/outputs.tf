output "resource_group_name" {
  description = "Name of the provisioned resource group."
  value       = azurerm_resource_group.main.name
}

output "location" {
  description = "Azure region where resources were deployed."
  value       = azurerm_resource_group.main.location
}

output "virtual_network_name" {
  description = "VNet name."
  value       = azurerm_virtual_network.main.name
}

output "virtual_network_id" {
  description = "VNet resource ID."
  value       = azurerm_virtual_network.main.id
}

output "subnet_id" {
  description = "Application subnet ID."
  value       = azurerm_subnet.app.id
}

output "vm_name" {
  description = "Linux VM name."
  value       = azurerm_linux_virtual_machine.app.name
}

output "vm_id" {
  description = "Linux VM resource ID."
  value       = azurerm_linux_virtual_machine.app.id
}

output "vm_private_ip" {
  description = "Private IP of the VM (from NIC)."
  value       = azurerm_network_interface.vm.private_ip_address
}

output "vm_public_ip" {
  description = "Public IP address for SSH and HTTP to the app."
  value       = azurerm_public_ip.vm.ip_address
}

output "ssh_command" {
  description = "Example SSH command (replace key path if needed)."
  value       = "ssh -i ~/.ssh/id_rsa ${var.admin_username}@${azurerm_public_ip.vm.ip_address}"
}

output "app_url" {
  description = "URL to open the Flask app after deployment on the VM."
  value       = "http://${azurerm_public_ip.vm.ip_address}:${var.app_port}"
}

output "storage_account_name" {
  description = "Storage account name (globally unique)."
  value       = azurerm_storage_account.app.name
}

output "storage_container_name" {
  description = "Blob container for application data / artifacts."
  value       = azurerm_storage_container.appdata.name
}

output "network_security_group_id" {
  description = "NSG resource ID."
  value       = azurerm_network_security_group.main.id
}
