# FAST STAGING Infrastructure

> SAMPLE/DEMO IaC for the FAST integration runtime in the combined STAGING environment (SYS/INT/ACC).

## Scope
- Creates the `fast-stg-vnet` network with dedicated Azure Firewall, service mesh, storage, and database subnets.
- Applies UDRs so pre-production test traffic follows the same inspection path as production.
- Creates an Azure Firewall Policy with rules for landing zone storage/database access, corporate LAN ingress, on-prem file transfer, and Microsoft 365/SharePoint egress.

## Deployment
```bash
az deployment group create \
  --resource-group <rg-fast-stg> \
  --template-file main.bicep \
  --parameters @parameters.json
```

## Notes
- CIDR range: `10.1.0.0/16`
- Resource naming prefix: `fast-stg`
- This environment represents SYS, INT, and ACC together for the sample repository.
