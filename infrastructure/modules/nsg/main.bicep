targetScope = 'resourceGroup'

@description('Name of the Network Security Group to create.')
param nsgName string

@description('Azure region for the NSG.')
param location string = resourceGroup().location

@description('Security rules to apply to the NSG. SAMPLE/DEMO values are expected from the environment wrappers.')
param securityRules array

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [for rule in securityRules: {
      name: rule.name
      properties: union({
        description: contains(rule, 'description') ? rule.description : 'SAMPLE/DEMO NSG rule for FAST'
        priority: rule.priority
        direction: rule.direction
        access: rule.access
        protocol: rule.protocol
      }, contains(rule, 'sourcePortRange') ? {
        sourcePortRange: rule.sourcePortRange
      } : {}, contains(rule, 'sourcePortRanges') ? {
        sourcePortRanges: rule.sourcePortRanges
      } : {}, contains(rule, 'destinationPortRange') ? {
        destinationPortRange: rule.destinationPortRange
      } : {}, contains(rule, 'destinationPortRanges') ? {
        destinationPortRanges: rule.destinationPortRanges
      } : {}, contains(rule, 'sourceAddressPrefix') ? {
        sourceAddressPrefix: rule.sourceAddressPrefix
      } : {}, contains(rule, 'sourceAddressPrefixes') ? {
        sourceAddressPrefixes: rule.sourceAddressPrefixes
      } : {}, contains(rule, 'destinationAddressPrefix') ? {
        destinationAddressPrefix: rule.destinationAddressPrefix
      } : {}, contains(rule, 'destinationAddressPrefixes') ? {
        destinationAddressPrefixes: rule.destinationAddressPrefixes
      } : {})
    }]
  }
}

output nsgId string = nsg.id
output nsgName string = nsg.name
