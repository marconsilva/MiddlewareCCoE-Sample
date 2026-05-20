targetScope = 'resourceGroup'

// SAMPLE/DEMO environment wrapper that composes reusable networking and NSG modules for FAST PRODUCTION.
param location string = resourceGroup().location
param namePrefix string
param vnetAddressSpace string
param subnetPrefixes object
param corpLanPrefixes array
param onPremFabricPrefixes array
param storageProviderPrefix string
param databaseProviderPrefix string
param firewallPrivateIp string

module meshNsg '../../modules/nsg/main.bicep' = {
  name: '${namePrefix}-mesh-nsg'
  params: {
    nsgName: '${namePrefix}-nsg-mesh'
    location: location
    securityRules: [
      {
        name: 'Allow-Corporate-Inbound-Web'
        description: 'Allow SAMPLE/DEMO corporate LAN access to the FAST UI and APIs via the service mesh ingress.'
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRanges: [
          '80'
          '443'
        ]
        sourceAddressPrefixes: corpLanPrefixes
        destinationAddressPrefix: subnetPrefixes.serviceMesh
      }
      {
        name: 'Allow-Mesh-To-Storage'
        description: 'Allow FAST workloads to reach the dedicated landing zone storage endpoint.'
        priority: 200
        direction: 'Outbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '443'
        sourceAddressPrefix: subnetPrefixes.serviceMesh
        destinationAddressPrefix: storageProviderPrefix
      }
      {
        name: 'Allow-Mesh-To-Database'
        description: 'Allow FAST workloads to reach PostgreSQL in the dedicated landing zone.'
        priority: 210
        direction: 'Outbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '5432'
        sourceAddressPrefix: subnetPrefixes.serviceMesh
        destinationAddressPrefix: databaseProviderPrefix
      }
      {
        name: 'Allow-Mesh-To-FileTransfer'
        description: 'Allow HTTPS traffic from FAST to on-premise file transfer providers.'
        priority: 220
        direction: 'Outbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '443'
        sourceAddressPrefix: subnetPrefixes.serviceMesh
        destinationAddressPrefixes: onPremFabricPrefixes
      }
      {
        name: 'Allow-Mesh-To-Internet-SaaS'
        description: 'Allow HTTPS egress to Microsoft Graph and SharePoint via the Azure Firewall.'
        priority: 230
        direction: 'Outbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '443'
        sourceAddressPrefix: subnetPrefixes.serviceMesh
        destinationAddressPrefix: 'Internet'
      }
    ]
  }
}

module storageNsg '../../modules/nsg/main.bicep' = {
  name: '${namePrefix}-storage-nsg'
  params: {
    nsgName: '${namePrefix}-nsg-storage'
    location: location
    securityRules: [
      {
        name: 'Allow-ServiceMesh-To-Storage'
        description: 'Allow FAST service mesh workloads to reach the storage integration subnet over HTTPS.'
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '443'
        sourceAddressPrefix: subnetPrefixes.serviceMesh
        destinationAddressPrefix: subnetPrefixes.storage
      }
    ]
  }
}

module databaseNsg '../../modules/nsg/main.bicep' = {
  name: '${namePrefix}-database-nsg'
  params: {
    nsgName: '${namePrefix}-nsg-database'
    location: location
    securityRules: [
      {
        name: 'Allow-ServiceMesh-To-PostgreSql'
        description: 'Allow FAST workloads to access PostgreSQL over TCP/5432.'
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '5432'
        sourceAddressPrefix: subnetPrefixes.serviceMesh
        destinationAddressPrefix: subnetPrefixes.database
      }
    ]
  }
}

module networking '../../modules/networking/main.bicep' = {
  name: '${namePrefix}-vnet'
  params: {
    vnetName: '${namePrefix}-vnet'
    location: location
    addressSpace: vnetAddressSpace
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: subnetPrefixes.firewall
        }
      }
      {
        name: 'snet-aks-mesh'
        properties: {
          addressPrefix: subnetPrefixes.serviceMesh
          networkSecurityGroup: {
            id: meshNsg.outputs.nsgId
          }
          routeTable: {
            id: resourceId('Microsoft.Network/routeTables', '${namePrefix}-rt-mesh')
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.KeyVault'
            }
          ]
        }
      }
      {
        name: 'snet-storage-integration'
        properties: {
          addressPrefix: subnetPrefixes.storage
          networkSecurityGroup: {
            id: storageNsg.outputs.nsgId
          }
          routeTable: {
            id: resourceId('Microsoft.Network/routeTables', '${namePrefix}-rt-mesh')
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
      {
        name: 'snet-database-integration'
        properties: {
          addressPrefix: subnetPrefixes.database
          networkSecurityGroup: {
            id: databaseNsg.outputs.nsgId
          }
          routeTable: {
            id: resourceId('Microsoft.Network/routeTables', '${namePrefix}-rt-mesh')
          }
        }
      }
    ]
    routeTables: [
      {
        name: '${namePrefix}-rt-mesh'
        properties: {
          disableBgpRoutePropagation: false
          routes: [
            {
              name: 'to-fast-storage'
              properties: {
                addressPrefix: storageProviderPrefix
                nextHopType: 'VirtualAppliance'
                nextHopIpAddress: firewallPrivateIp
              }
            }
            {
              name: 'to-fast-database'
              properties: {
                addressPrefix: databaseProviderPrefix
                nextHopType: 'VirtualAppliance'
                nextHopIpAddress: firewallPrivateIp
              }
            }
            {
              name: 'to-corporate-lan'
              properties: {
                addressPrefix: corpLanPrefixes[0]
                nextHopType: 'VirtualAppliance'
                nextHopIpAddress: firewallPrivateIp
              }
            }
            {
              name: 'to-onprem-file-transfer'
              properties: {
                addressPrefix: onPremFabricPrefixes[0]
                nextHopType: 'VirtualAppliance'
                nextHopIpAddress: firewallPrivateIp
              }
            }
            {
              name: 'default-egress-via-firewall'
              properties: {
                addressPrefix: '0.0.0.0/0'
                nextHopType: 'VirtualAppliance'
                nextHopIpAddress: firewallPrivateIp
              }
            }
          ]
        }
      }
    ]
  }
}

output vnetId string = networking.outputs.vnetId
output meshNsgId string = meshNsg.outputs.nsgId
output storageNsgId string = storageNsg.outputs.nsgId
output databaseNsgId string = databaseNsg.outputs.nsgId
