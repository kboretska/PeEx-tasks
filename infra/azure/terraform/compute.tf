locals {
  cloud_init = var.enable_docker_cloud_init ? base64encode(templatefile("${path.module}/templates/cloud-init.yaml.tpl", {
    admin_username = var.admin_username
  })) : null
}

resource "azurerm_linux_virtual_machine" "app" {
  name                = "${var.name_prefix}-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.vm.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "${var.name_prefix}-os"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  custom_data = local.cloud_init

  tags = local.common_tags

  depends_on = [
    azurerm_subnet_network_security_group_association.app,
  ]
}
