# Create Application NICs
resource "azurerm_network_interface" "app" {
  count                         = local.enable_deployment ? local.application_server_count : 0
  name                          = "${upper(local.application_sid)}_app${format("%02d", count.index)}-nic"
  location                      = var.resource-group[0].location
  resource_group_name           = var.resource-group[0].name
  enable_accelerated_networking = local.app_sizing.compute.accelerated_networking

  ip_configuration {
    name                          = "IPConfig1"
    subnet_id                     = var.infrastructure.vnets.sap.subnet_app.is_existing ? data.azurerm_subnet.subnet-sap-app[0].id : azurerm_subnet.subnet-sap-app[0].id
    private_ip_address            = var.infrastructure.vnets.sap.subnet_app.is_existing ? local.app_nic_ips[count.index] : cidrhost(var.infrastructure.vnets.sap.subnet_app.prefix, tonumber(count.index) + local.ip_offsets.app_vm)
    private_ip_address_allocation = "static"
  }
}

# Create the Application VM(s)
resource "azurerm_linux_virtual_machine" "app" {
  count                        = local.enable_deployment ? local.application_server_count : 0
  name                         = "${upper(local.application_sid)}_app${format("%02d", count.index)}"
  computer_name                = "${lower(local.application_sid)}app${format("%02d", count.index)}"
  location                     = var.resource-group[0].location
  resource_group_name          = var.resource-group[0].name
  availability_set_id          = azurerm_availability_set.app[0].id
  proximity_placement_group_id = lookup(var.infrastructure, "ppg", false) != false ? (var.ppg[0].id) : null
  network_interface_ids = [
    azurerm_network_interface.app[count.index].id
  ]
  size                            = local.app_sizing.compute.vm_size
  admin_username                  = local.authentication.username
  disable_password_authentication = true

  os_disk {
    name                 = "${upper(local.application_sid)}_app${format("%02d", count.index)}-osDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = local.os.publisher
    offer     = local.os.offer
    sku       = local.os.sku
    version   = local.os.version
  }

  admin_ssh_key {
    username   = local.authentication.username
    public_key = file(var.sshkey.path_to_public_key)
  }

  boot_diagnostics {
    storage_account_uri = var.storage-bootdiag.primary_blob_endpoint
  }
}

# Creates managed data disk
resource "azurerm_managed_disk" "app" {
  count                = local.enable_deployment ? length(local.app-data-disks) : 0
  name                 = local.app-data-disks[count.index].name
  location             = var.resource-group[0].location
  resource_group_name  = var.resource-group[0].name
  create_option        = "Empty"
  storage_account_type = local.app-data-disks[count.index].disk_type
  disk_size_gb         = local.app-data-disks[count.index].size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "app" {
  count                     = local.enable_deployment ? length(azurerm_managed_disk.app) : 0
  managed_disk_id           = azurerm_managed_disk.app[count.index].id
  virtual_machine_id        = azurerm_linux_virtual_machine.app[local.app-data-disks[count.index].vm_index].id
  caching                   = local.app-data-disks[count.index].caching
  write_accelerator_enabled = local.app-data-disks[count.index].write_accelerator
  lun                       = count.index
}
