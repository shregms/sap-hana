variable "resource-group" {
  description = "Details of the resource group"
}

variable "subnet-mgmt" {
  description = "Details of the management subnet"
}

variable "nsg-mgmt" {
  description = "Details of the management NSG"
}

variable "storage-bootdiag" {
  description = "Details of the boot diagnostics storage account"
}

variable "output-json" {
  description = "Details of the output JSON"
}

variable "ansible-inventory" {
  description = "Details of the Ansible inventory"
}

variable "random-id" {
  description = "Random hex for creating unique Azure key vault name"
}

variable "deployer-uai" {
  description = "Details of the UAI used by deployer(s)"
}

locals {
  output-tf = jsondecode(var.output-json.content)

  # Linux jumpbox information
  vm-jump-linux = [
    for jumpbox in var.jumpboxes.linux : jumpbox
  ]

  # Windows jumpbox information
  vm-jump-win = [
    for jumpbox in var.jumpboxes.windows : jumpbox
  ]
}
