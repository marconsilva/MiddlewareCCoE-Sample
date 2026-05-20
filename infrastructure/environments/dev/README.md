# FAST DEV Infrastructure

> SAMPLE/DEMO IaC for the FAST integration runtime in the DEV environment.

## Scope
- Creates the `fast-dev-vnet` network with dedicated Azure Firewall, service mesh, storage, and database subnets.
- Applies UDRs so private, corporate, file transfer, and internet egress traffic is steered through Azure Firewall.
- Creates an Azure Firewall Policy with rules for landing zone storage/database access, corporate LAN ingress, on-prem file transfer, and Microsoft 365/SharePoint egress.

## Deployment
```bash
az deployment group create \
  --resource-group <rg-fast-dev> \
  --template-file main.bicep \
  --parameters @parameters.json
```

## Notes
- CIDR range: `10.0.0.0/16`
- Resource naming prefix: `fast-dev`
- File transfer connectivity is represented by the `onPremFabricPrefixes` and Azure Firewall rule collections.
