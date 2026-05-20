targetScope = 'resourceGroup'

// SAMPLE/DEMO firewall rules for FAST PRODUCTION.
param location string = resourceGroup().location
param namePrefix string
param corpLanPrefixes array
param onPremFabricPrefixes array
param storageProviderPrefix string
param databaseProviderPrefix string
param serviceMeshSubnetPrefix string
param internetEgressFqdns array

module firewall '../../modules/firewall/main.bicep' = {
  name: '${namePrefix}-firewall-policy'
  params: {
    firewallPolicyName: '${namePrefix}-afw-policy'
    ruleCollectionGroupName: '${namePrefix}-fast-rcg'
    location: location
    networkRuleCollections: [
      {
        name: 'fast-private-connectivity'
        priority: 100
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'mesh-to-storage'
            ruleType: 'NetworkRule'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              serviceMeshSubnetPrefix
            ]
            destinationAddresses: [
              storageProviderPrefix
            ]
            destinationPorts: [
              '443'
            ]
          }
          {
            name: 'mesh-to-postgresql'
            ruleType: 'NetworkRule'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              serviceMeshSubnetPrefix
            ]
            destinationAddresses: [
              databaseProviderPrefix
            ]
            destinationPorts: [
              '5432'
            ]
          }
        ]
      }
      {
        name: 'fast-corporate-ingress'
        priority: 200
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'corporate-to-ui-and-apis'
            ruleType: 'NetworkRule'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: corpLanPrefixes
            destinationAddresses: [
              serviceMeshSubnetPrefix
            ]
            destinationPorts: [
              '80'
              '443'
            ]
          }
        ]
      }
      {
        name: 'fast-file-transfer'
        priority: 300
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'mesh-to-onprem-file-transfer'
            ruleType: 'NetworkRule'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              serviceMeshSubnetPrefix
            ]
            destinationAddresses: onPremFabricPrefixes
            destinationPorts: [
              '443'
            ]
          }
        ]
      }
    ]
    applicationRuleCollections: [
      {
        name: 'fast-internet-egress'
        priority: 400
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'mesh-to-m365-and-sharepoint'
            ruleType: 'ApplicationRule'
            sourceAddresses: [
              serviceMeshSubnetPrefix
            ]
            targetFqdns: internetEgressFqdns
            terminateTLS: false
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
          }
        ]
      }
    ]
  }
}

output firewallPolicyId string = firewall.outputs.firewallPolicyId
