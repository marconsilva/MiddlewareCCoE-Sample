targetScope = 'resourceGroup'

// SAMPLE/DEMO orchestrator for the FAST DEV environment.
@description('Azure region used for FAST DEV resources.')
param location string = resourceGroup().location

@description('Naming prefix applied to all FAST resources.')
param namePrefix string

@description('CIDR block for the FAST environment VNET.')
param vnetAddressSpace string

@description('Subnet prefixes for the Azure Firewall, AKS/service mesh, storage, and database tiers.')
param subnetPrefixes object

@description('Corporate LAN source ranges that can reach FAST UI and APIs.')
param corpLanPrefixes array

@description('On-premise corporate fabric ranges that host the file transfer providers.')
param onPremFabricPrefixes array

@description('Landing zone storage subnet/provider range.')
param storageProviderPrefix string

@description('Landing zone database subnet/provider range.')
param databaseProviderPrefix string

@description('FQDNs that FAST is allowed to reach on the public internet.')
param internetEgressFqdns array

@description('Private IP address of the Azure Firewall used as next hop in the UDRs.')
param firewallPrivateIp string

module networking './networking.bicep' = {
  name: '${namePrefix}-networking'
  params: {
    location: location
    namePrefix: namePrefix
    vnetAddressSpace: vnetAddressSpace
    subnetPrefixes: subnetPrefixes
    corpLanPrefixes: corpLanPrefixes
    onPremFabricPrefixes: onPremFabricPrefixes
    storageProviderPrefix: storageProviderPrefix
    databaseProviderPrefix: databaseProviderPrefix
    firewallPrivateIp: firewallPrivateIp
  }
}

module firewall './firewall-rules.bicep' = {
  name: '${namePrefix}-firewall'
  params: {
    location: location
    namePrefix: namePrefix
    corpLanPrefixes: corpLanPrefixes
    onPremFabricPrefixes: onPremFabricPrefixes
    storageProviderPrefix: storageProviderPrefix
    databaseProviderPrefix: databaseProviderPrefix
    serviceMeshSubnetPrefix: subnetPrefixes.serviceMesh
    internetEgressFqdns: internetEgressFqdns
  }
  dependsOn: [
    networking
  ]
}

output vnetId string = networking.outputs.vnetId
output firewallPolicyId string = firewall.outputs.firewallPolicyId
