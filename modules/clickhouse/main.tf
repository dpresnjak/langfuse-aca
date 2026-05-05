resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = "${var.name_prefix}-clickhouse"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = "azureuser"

  network_interface_ids = [var.network_interface_id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = var.tags
}

resource "azurerm_managed_disk" "data" {
  name                 = "${var.name_prefix}-clickhouse-data"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.disk_size_gb
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  managed_disk_id    = azurerm_managed_disk.data.id
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  lun                = 0
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_extension" "install_clickhouse" {
  name                 = "install-clickhouse"
  virtual_machine_id   = azurerm_linux_virtual_machine.this.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  protected_settings = jsonencode({
    script = base64encode(templatefile("${path.module}/install-clickhouse.sh.tftpl", {
      clickhouse_user     = var.clickhouse_user
      clickhouse_password = var.clickhouse_password
      disk_device         = "/dev/disk/azure/scsi1/lun0"
    }))
  })

  depends_on = [azurerm_virtual_machine_data_disk_attachment.data]
}
