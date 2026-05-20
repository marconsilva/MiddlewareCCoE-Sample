# Middleware CCoE — Multi-Environment Infrastructure Sample

> **A sample repository demonstrating how a Middleware Cloud Center of Excellence (CCoE) manages Azure infrastructure across Dev → Staging → Production using GitOps, GitHub Issues, and Agentic AI workflows.**

---

## 🎯 Purpose

This repository showcases a complete workflow for managing enterprise middleware infrastructure on Azure:

1. **A user submits a request** via a GitHub Issue template (e.g., "add a new API connectivity rule")
2. **An AI agent processes the request**, generates the required Infrastructure as Code (IaC) changes, and creates a Pull Request
3. **The PR is reviewed** by both humans and an AI reviewer agent
4. **On merge**, changes deploy automatically through a multi-environment pipeline with approval gates

This pattern enables self-service infrastructure changes while maintaining governance, auditability, and security through code review and environment promotion.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         USER REQUEST FLOW                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────┐    ┌──────────────┐    ┌────────────────┐    ┌────────┐  │
│  │  GitHub  │───▶│ Issue Triage │───▶│ Intake Agent   │───▶│   PR   │  │
│  │  Issue   │    │  Workflow    │    │ (IaC Changes)  │    │ Review │  │
│  └──────────┘    └──────────────┘    └────────────────┘    └───┬────┘  │
│                                                                 │       │
├─────────────────────────────────────────────────────────────────┼───────┤
│                     DEPLOYMENT PIPELINE                          │       │
├─────────────────────────────────────────────────────────────────┼───────┤
│                                                                 ▼       │
│  ┌──────────┐    ┌──────────────┐    ┌────────────────┐               │
│  │   DEV    │───▶│   STAGING    │───▶│  PRODUCTION    │               │
│  │  (auto)  │    │  (approval)  │    │ (multi-approve)│               │
│  └──────────┘    └──────────────┘    └────────────────┘               │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📁 Repository Structure

```
├── .github/
│   ├── ISSUE_TEMPLATE/              # Issue forms for change requests
│   │   ├── config.yml               # Template chooser configuration
│   │   ├── new-connectivity-request.yml
│   │   ├── modify-connectivity.yml
│   │   ├── update-service-mesh.yml
│   │   └── infrastructure-change.yml
│   ├── agents/                      # Custom Copilot agents
│   │   ├── intake-processor.md      # Processes issues → IaC changes
│   │   ├── pr-reviewer.md           # Reviews infrastructure PRs
│   │   └── environment-promoter.md  # Handles env promotion
│   └── workflows/                   # GitHub Actions workflows
│       ├── issue-triage.yml         # Validates & routes issues
│       ├── agentic-iac-change.yml   # Agent generates IaC + creates PR
│       ├── validate-iac.yml         # PR validation (lint, what-if)
│       ├── deploy-dev.yml           # Auto-deploy to DEV
│       ├── deploy-staging.yml       # Deploy to Staging (approval)
│       ├── deploy-production.yml    # Deploy to Production (approval)
│       └── promote-environment.yml  # Reusable promotion workflow
├── infrastructure/
│   ├── environments/                # Per-environment configurations
│   │   ├── dev/                     # DEV environment (10.0.0.0/16)
│   │   ├── staging/                 # Staging environment (10.1.0.0/16)
│   │   └── production/             # Production environment (10.2.0.0/16)
│   ├── modules/                     # Reusable Bicep modules
│   │   ├── firewall/                # Azure Firewall policies
│   │   ├── networking/              # VNET, subnets, UDRs
│   │   └── nsg/                     # Network Security Groups
│   └── kubernetes/                  # Kubernetes/Service Mesh configs
│       ├── base/                    # Base manifests
│       │   ├── argocd/              # ArgoCD Application & Project
│       │   ├── istio-config/        # Istio VirtualServices, mTLS, etc.
│       │   └── network-policies/    # Kubernetes NetworkPolicies
│       └── overlays/                # Kustomize per-environment overlays
│           ├── dev/
│           ├── staging/
│           └── production/
└── sample/                          # Reference intake examples
    ├── T002957293-FAST-v1.json      # Sample FAST solution intake
    ├── prelude-intake-schema.md     # Intake JSON schema reference
    └── prelude-create-intake-json.md # Intake creation guide
```

---

## 🚀 How It Works

### Step 1: Submit a Change Request

Navigate to **Issues → New Issue** and select one of the available templates:

| Template | Use Case |
|----------|----------|
| **New Connectivity Request** | Onboard a new application to the middleware platform |
| **Modify Connectivity** | Add/remove consumers, update firewall or NSG rules |
| **Update Service Mesh** | Change Istio VirtualServices, DestinationRules, etc. |
| **Infrastructure Change** | General firewall, VNET, UDR, or NSG changes |

Fill in the structured form with your requirements (application name, environments, protocols, locations, etc.).

### Step 2: Automated Processing

Once submitted, the following happens automatically:

1. **Issue Triage** (`issue-triage.yml`) validates the request and posts an acknowledgment
2. **Agentic IaC Change** (`agentic-iac-change.yml`) dispatches the **Intake Processor** agent which:
   - Parses your request parameters
   - Generates appropriate Bicep/YAML changes across requested environments
   - Creates a feature branch (`infra/{issue-number}-{description}`)
   - Opens a Pull Request linked to your issue

### Step 3: Review & Approval

- The **PR Reviewer** agent automatically reviews the generated changes for security and consistency
- Human reviewers validate the changes
- The **Validate IaC** workflow runs linting and what-if checks across all environments

### Step 4: Deployment Pipeline

Once the PR is merged to `main`:

| Stage | Environment | Trigger | Approval |
|-------|-------------|---------|----------|
| 1 | **DEV** | Automatic on merge | None |
| 2 | **Staging** | After DEV succeeds | 1 reviewer |
| 3 | **Production** | Manual trigger | 2+ reviewers |

The **Environment Promoter** agent assists with generating promotion PRs that carry functional changes while preserving environment-specific values.

---

## 🏢 Sample Solution: FAST

The repository includes a complete infrastructure example for a solution called **FAST** (ATP Integration Run Time), which demonstrates:

### Azure Infrastructure (Bicep)
- **Firewall Rules**: Connectivity between Azure Enterprise Service Mesh and dedicated landing zones, internet access for O365/SharePoint, on-premise corporate fabric access
- **VNETs**: Hub-spoke topology with service mesh, application, and data subnets
- **UDRs**: Traffic routing through the Azure Firewall
- **NSGs**: Granular port-level security for each subnet

### Kubernetes / Service Mesh (YAML)
- **ArgoCD**: GitOps-managed application deployment with automatic sync
- **Istio Service Mesh**: 
  - VirtualServices for `ui-default`, `api-etl`, `api-model`
  - DestinationRules with strict mTLS
  - AuthorizationPolicies per consumer
  - Gateway configuration for ingress

### Connectivity Types Demonstrated
- Backend connectivity (storage accounts, PostgreSQL)
- API connectivity (REST APIs with application auth)
- UI connectivity (browser access with end-user auth)
- Enterprise file transfer containers
- External service access (O365 Graph API, SharePoint)

---

## 🤖 Custom Agents

This repository includes three specialized Copilot agents:

### Intake Processor (`.github/agents/intake-processor.md`)
Processes infrastructure change requests from GitHub Issues. It understands the middleware domain, interprets user intent, and generates compliant IaC changes following repository patterns.

### PR Reviewer (`.github/agents/pr-reviewer.md`)
Reviews infrastructure PRs for security best practices, least-privilege firewall rules, proper mTLS configuration, and environment consistency.

### Environment Promoter (`.github/agents/environment-promoter.md`)
Assists with promoting changes across environments, maintaining environment-specific values (CIDR ranges, resource names) while carrying functional changes forward.

---

## 🔧 Environments

| Environment | CIDR Range | Purpose | Deployment |
|-------------|-----------|---------|------------|
| **DEV** | 10.0.0.0/16 | Development & testing | Automatic |
| **Staging** | 10.1.0.0/16 | Integration & acceptance | Manual approval |
| **Production** | 10.2.0.0/16 | Live workloads | Multi-party approval |

---

## 📋 Prerequisites

To use this repository as a template for your own CCoE:

1. **GitHub Repository** with Actions enabled
2. **Azure Subscription** with appropriate permissions
3. **GitHub Environments** configured (`dev`, `staging`, `production`) with protection rules
4. **Repository Secrets**:
   - `AZURE_CREDENTIALS` — Service principal for Azure deployments
   - `AZURE_SUBSCRIPTION_ID` — Target subscription
5. **GitHub Copilot** enabled for agentic workflows

---

## 🏁 Getting Started

1. **Fork or use as template** for your organization
2. **Configure environments** in Settings → Environments (add reviewers for staging/production)
3. **Set up secrets** for Azure connectivity
4. **Customize the IaC** in `infrastructure/` to match your actual Azure topology
5. **Create your first issue** using one of the templates to see the workflow in action

---

## 📖 Further Reading

- [Azure Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Istio Service Mesh](https://istio.io/latest/docs/)
- [ArgoCD GitOps](https://argo-cd.readthedocs.io/)
- [GitHub Actions Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments)
- [GitHub Copilot Agents](https://docs.github.com/en/copilot)

---

## 📝 License

This is a sample repository for demonstration purposes. Adapt and extend for your organization's needs.
