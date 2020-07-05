data azurerm_subscription primary {}

locals {
  policy_set_name = substr("${var.env}-${var.userDefinedString} diagnostic policy set", 0, 64)
  policies = {
    AA = {
      name        = "Deploy-Diagnostics-AA"
      description = "Apply diagnostic settings for Azure Automation Accounts - Log Analytics"
    },
    ActivityLog = {
      name        = "Deploy-Diagnostics-ActivityLog"
      description = "Ensures that Activity Log Diagnostics settings are set to push logs into Log Analytics"
    },
    KeyVault = {
      name        = "Deploy-Diagnostics-KeyVault"
      description = "Apply diagnostic settings for Azure KeyVault - Log Analytics"
    },
    NIC = {
      name        = "Deploy-Diagnostics-NIC"
      description = "Apply diagnostic settings for Azure NIC - Log Analytics"
    },
    NSG = {
      name        = "Deploy-Diagnostics-NSG"
      description = "Apply diagnostic settings for Azure NSG - Log Analytics"
    },
    Recovery_Vault = {
      name        = "Deploy-Diagnostics-Recovery_Vault"
      description = "Apply diagnostic settings for Azure Recovery Vault - Log Analytics"
    },
    VM = {
      name        = "Deploy-Diagnostics-VM"
      description = "Apply diagnostic settings for Azure VM - Log Analytics"
    },
    VMSS = {
      name        = "Deploy-Diagnostics-VMSS"
      description = "Apply diagnostic settings for Azure VM Scale Set - Log Analytics"
    },
    VNET = {
      name        = "Deploy-Diagnostics-VNET"
      description = "Apply diagnostic settings for Azure VNET - Log Analytics"
    }
  }
  subscriptionID = data.azurerm_subscription.primary.subscription_id
  policy_assignment = [
    for policy in local.policies :
    {
      "parameters" : {
        "logAnalytics" : {
          "value" : "[parameters('logAnalytics')]"
        },
        "prefix" : {
          "value" : "[parameters('prefix')]"
        }
      },
      "policyDefinitionId" : "/subscriptions/${local.subscriptionID}/providers/Microsoft.Authorization/policyDefinitions/${policy.name}"
    }
  ]
}

resource "azurerm_policy_definition" "policy_definition" {
  for_each = var.deploy ? local.policies : {}

  name         = each.value.name
  policy_type  = "Custom"
  mode         = "All"
  display_name = each.value.name
  description  = each.value.description
  parameters   = file("${path.module}/policies/Deploy-Diagnostics-parameters.json")
  policy_rule  = file("${path.module}/policies/${each.value.name}.json")
}

resource "azurerm_policy_set_definition" "policy_set_definition" {
  depends_on         = [azurerm_policy_definition.policy_definition]
  count              = var.deploy ? 1 : 0
  name               = local.policy_set_name
  policy_type        = "Custom"
  display_name       = local.policy_set_name
  parameters         = file("${path.module}/policies/Deploy-Diagnostics-parameters.json")
  policy_definitions = jsonencode(local.policy_assignment)
}

resource "azurerm_policy_assignment" "policy_assignment" {
  count                = var.deploy ? 1 : 0
  name                 = local.policy_set_name
  location             = var.log_analytics_workspace.location
  scope                = data.azurerm_subscription.primary.id
  policy_definition_id = azurerm_policy_set_definition.policy_set_definition[0].id
  display_name         = local.policy_set_name
  description          = "Apply diagnostic settings for Azure for PBMM Guardrails compliance"
  identity {
    type = "SystemAssigned"
  }
  parameters = <<PARAMETERS
  {
    "logAnalytics": {
      "value": "${var.log_analytics_workspace.id}"
    },
    "prefix": {
      "value": "${var.log_analytics_workspace.name}-"
    }
  }
PARAMETERS
}