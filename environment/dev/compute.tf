resource "azurerm_linux_virtual_machine_scale_set" "app" {
  name                = "vmss-app-${var.environment}"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  sku                 = "Standard_D2s_v5"
  instances           = 2
  admin_username      = "azureuser"
  admin_password      = random_password.vm_admin_password.result
  disable_password_authentication = false

  # Assign the User-Assigned Managed Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "StandardSSD_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "nic-app"
    primary = true

    ip_configuration {
      name      = "ipconfig-internal"
      primary   = true
      subnet_id = module.spoke_network.subnet_ids["app-subnet"]
    }
  }

  # Cloud-Init / Custom Data passing the Secret URI
  custom_data = base64encode(<<-EOF
              #!/bin/bash
              echo "KEYVAULT_SECRET_URI=${azurerm_key_vault_secret.db_password.versionless_id}" >> /etc/environment
              echo "DB_HOST=${azurerm_postgresql_flexible_server.this.fqdn}" >> /etc/environment
              EOF
  )

  depends_on = [
    azurerm_role_assignment.app_kv_reader,
    azurerm_postgresql_flexible_server.this
  ]
}