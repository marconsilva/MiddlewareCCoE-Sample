# FAST PRODUCTION Infrastructure

> SAMPLE/DEMO IaC for the FAST integration runtime in the combined PRODUCTION environment (PRD/PSU).

## Scope
- Creates the `fast-prd-vnet` network with dedicated Azure Firewall, service mesh, storage, and database subnets.
- Applies UDRs so production traffic to landing zones, corporate consumers, file transfer providers, and internet SaaS endpoints is centrally inspected.
- Creates an Azure Firewall Policy with realistic rule collections for storage, PostgreSQL, UI/API ingress, and Microsoft Graph/SharePoint egress.

## Deployment
```bash
az deployment group create \
  --resource-group <rg-fast-prd> \
  --template-file main.bicep \
  --parameters @parameters.json
```

## Notes
- CIDR range: `10.2.0.0/16`
- Resource naming prefix: `fast-prd`
- This environment represents both PRD and PSU for the sample repository.
