targetScope = 'resourceGroup'

@description('Name of the virtual network.')
param vnetName string

@description('Azure region for all networking resources.')
param location string = resourceGroup().location

@description('Primary address space for the virtual network.')
param addressSpace string

@description('Optional custom DNS servers for the VNET.')
param dnsServers array = []

@description('Subnet resources already shaped for the Microsoft.Network virtualNetworks API.')
param subnets array

@description('Route table resources already shaped for the Microsoft.Network routeTables API.')
param routeTables array = []

resource routeTableResources 'Microsoft.Network/routeTables@2023-09-01' = [for rt in routeTables: {
  name: rt.name
  location: location
  properties: rt.properties
}]

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: union({
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    subnets: subnets
  }, length(dnsServers) > 0 ? {
    dhcpOptions: {
      dnsServers: dnsServers
    }
  } : {})
}

output vnetId string = vnet.id
output subnetResourceIds array = [for subnet in subnets: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, subnet.name)]
output routeTableNames array = [for rt in routeTables: rt.name]
