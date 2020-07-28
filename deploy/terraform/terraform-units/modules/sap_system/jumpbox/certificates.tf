##################################################################################################################
# CERTIFICATES FOR WINRM
##################################################################################################################

# Imports current user or service principal profile details
data "azurerm_client_config" "current" {}

# Creates Azure key vault
resource "azurerm_key_vault" "key-vault" {
  count               = length(local.vm-jump-win) > 0 ? 1 : 0
  name                = "winrm-kv-${var.random-id.hex}"
  location            = var.resource-group[0].location
  resource_group_name = var.resource-group[0].name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  enabled_for_deployment          = true
  enabled_for_template_deployment = true

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = var.deployer-uai.principal_id

    certificate_permissions = [
      "create",
      "delete",
      "get",
      "update",
    ]

    key_permissions    = []
    secret_permissions = []
  }
}

# Creates Azure key vault certificates
resource "azurerm_key_vault_certificate" "key-vault-cert" {
  count        = length(var.jumpboxes.windows)
  name         = "${var.jumpboxes.windows[count.index].name}-cert"
  key_vault_id = try(azurerm_key_vault.key-vault[0].id, null)

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject            = "CN=${var.jumpboxes.windows[count.index].name}"
      validity_in_months = 12
    }
  }
}
