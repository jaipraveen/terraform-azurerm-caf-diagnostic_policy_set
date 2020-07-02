# https://github.com/Azure/Enterprise-Scale/blob/main/docs/reference/contoso/e2e-landing-zone-vwan-orchestration.parameters.json

resource "azurerm_policy_definition" "Deploy-Diagnostics-VMSS" {
  # count        = var.deployOptionalFeatures.deny_publicips_on_nics ? 1 : 0
  name         = "Deploy-Diagnostics-VMSS"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Deploy-Diagnostics-VMSS"
  description  = "Apply diagnostic settings for Azure VMSS - Log Analytics"
  parameters   = <<PARAMETERS
  {
    "logAnalytics": {
      "type": "String",
      "metadata": {
        "displayName": "Log Analytics workspace",
        "description": "Select the Log Analytics workspace from dropdown list",
        "strongType": "omsWorkspace"
      }
    }
  }
PARAMETERS
  policy_rule  = <<POLICY_RULE
  {
    "if": {
      "field": "type",
      "equals": "Microsoft.Compute/virtualMachineScaleSets"
    },
    "then": {
      "effect": "deployIfNotExists",
      "details": {
        "type": "Microsoft.Insights/diagnosticSettings",
        "name": "setByPolicy",
        "existenceCondition": {
          "allOf": [
            {
              "field": "Microsoft.Insights/diagnosticSettings/metrics.enabled",
              "equals": "true"
            },
            {
              "field": "Microsoft.Insights/diagnosticSettings/workspaceId",
              "equals": "[parameters('logAnalytics')]"
            }
          ]
        },
        "roleDefinitionIds": [
          "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
        ],
        "deployment": {
          "properties": {
            "mode": "incremental",
            "template": {
              "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
              "contentVersion": "1.0.0.0",
              "parameters": {
                "resourceName": {
                  "type": "string"
                },
                "logAnalytics": {
                  "type": "string"
                },
                "location": {
                  "type": "string"
                }
              },
              "variables": {},
              "resources": [
                {
                  "type": "Microsoft.Compute/virtualMachineScaleSets/providers/diagnosticSettings",
                  "apiVersion": "2017-05-01-preview",
                  "name": "[concat(parameters('resourceName'), '/', 'Microsoft.Insights/setByPolicy')]",
                  "location": "[parameters('location')]",
                  "dependsOn": [],
                  "properties": {
                    "workspaceId": "[parameters('logAnalytics')]",
                    "metrics": [
                      {
                        "category": "AllMetrics",
                        "enabled": true,
                        "retentionPolicy": {
                          "enabled": false,
                          "days": 0
                        }
                      }
                    ],
                    "logs": []
                  }
                }
              ],
              "outputs": {}
            },
            "parameters": {
              "logAnalytics": {
                "value": "[parameters('logAnalytics')]"
              },
              "location": {
                "value": "[field('location')]"
              },
              "resourceName": {
                "value": "[field('name')]"
              }
            }
          }
        }
      }
    }
  }
POLICY_RULE
}
/*
resource "azurerm_policy_assignment" "Deploy-Diagnostics-VMSS" {
  # count                = var.deployOptionalFeatures.deny_publicips_on_nics ? 1 : 0
  name                 = "Deploy-Diagnostics-VMSS"
  location             = var.log_analytics_workspace.location
  scope                = data.azurerm_subscription.primary.id
  policy_definition_id = azurerm_policy_definition.Deploy-Diagnostics-VMSS.id
  display_name         = "Deploy-Diagnostics-VMSS"
  description          = "Apply diagnostic settings for Azure Automation Accounts - Log Analytics"
  identity {
    type = "SystemAssigned"
  }
  parameters = <<PARAMETERS
  {
    "logAnalytics": {
      "value": "${var.log_analytics_workspace.id}"
    }
  }
PARAMETERS
}

resource "azurerm_policy_remediation" "Deploy-Diagnostics-VMSS" {
  name                 = lower("Deploy-Diagnostics-VMSS-policy-remediation")
  scope                = azurerm_policy_assignment.Deploy-Diagnostics-VMSS.scope
  policy_assignment_id = azurerm_policy_assignment.Deploy-Diagnostics-VMSS.id
  # location_filters     = ["West Europe"]
}
*/