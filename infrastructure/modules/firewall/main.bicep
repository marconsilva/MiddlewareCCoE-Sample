targetScope = 'resourceGroup'

@description('Name of the Azure Firewall Policy to create.')
param firewallPolicyName string

@description('Azure region for the firewall policy resources.')
param location string = resourceGroup().location

@description('Rule collection group name that contains the FAST connectivity rules.')
param ruleCollectionGroupName string = '${firewallPolicyName}-rcg'

@description('Network rule collections already shaped for the firewall policy rule collection group resource.')
param networkRuleCollections array = []

@description('Application rule collections already shaped for the firewall policy rule collection group resource.')
param applicationRuleCollections array = []

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-09-01' = {
  name: firewallPolicyName
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
  }
}

resource ruleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = {
  name: ruleCollectionGroupName
  parent: firewallPolicy
  properties: {
    priority: 200
    ruleCollections: concat(networkRuleCollections, applicationRuleCollections)
  }
}

output firewallPolicyId string = firewallPolicy.id
output ruleCollectionGroupId string = ruleCollectionGroup.id
