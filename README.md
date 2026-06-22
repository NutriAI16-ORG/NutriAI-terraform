# NutriAI — Terraform Infrastructure

> Azure infrastructure for the NutriAI Health Portal — a microservices platform running on AKS with private networking, Workload Identity, and Key Vault secret management.

---

## Table of Contents
1. [Identities Used and Why](#identities-used-and-why)
2. [Resources Created and How They Connect](#resources-created-and-how-they-connect)
3. [How the Pipeline Works](#how-the-pipeline-works)
4. [How the Self-Hosted Runner Gets Authenticated](#how-the-self-hosted-runner-gets-authenticated)
5. [How to Run Terraform Manually](#how-to-run-terraform-manually)
6. [Values to Update in K8s Manifests After Apply](#values-to-update-in-k8s-manifests-after-apply)
7. [Bootstrap Setup (One-Time)](#bootstrap-setup-one-time)

---

## Identities Used and Why

NutriAI uses three distinct identities, each with a specific, minimal scope of access:

### 1. AKS Cluster Identity (`nutriai-aks-identity-<env>`)
**Type:** User-Assigned Managed Identity
**Why it exists:** AKS needs an identity to manage its own Azure resources — creating load balancers, attaching managed disks, pulling images, and joining the VNet. Using a user-assigned (rather than system-assigned) identity gives full control over role assignments and makes it possible to pre-grant access before the cluster is created.

**Roles granted:**
| Role | Scope | Reason |
|---|---|---|
| Network Contributor | VNet | Attach load balancers, manage subnet IPs |
| AcrPull | Container Registry | Pull application images |

---

### 2. Application Workload Identity (`nutriai-workload-identity-<env>`)
**Type:** User-Assigned Managed Identity + Federated Credential
**Why it exists:** AKS pods need to authenticate to Azure services (Key Vault, Service Bus) **without any stored credentials** — no connection strings, no client secrets in environment variables. This identity, combined with AKS OIDC issuer + Kubernetes Service Account annotation, enables **Azure Workload Identity Federation**: a pod proves its identity via a short-lived Kubernetes OIDC token, which Azure exchanges for a real Azure AD token.

**How the federation chain works:**
```
AKS Pod
  │  token from: system:serviceaccount:nutriai-prod:nutriai-service-account
  ▼
AKS OIDC Issuer (public JWKS endpoint on the cluster)
  ▼
Azure AD Federated Identity Credential
  │  subject:  system:serviceaccount:nutriai-prod:nutriai-service-account
  │  issuer:   https://<aks-oidc-url>
  ▼
User-Assigned Managed Identity (nutriai-workload-identity-prod)
  ▼
Azure RBAC roles on target resources
```

**Roles granted:**
| Role | Scope | Reason |
|---|---|---|
| Key Vault Secrets User | Key Vault | Read secrets (via CSI driver) |
| Key Vault Reader | Key Vault | List and describe secrets |
| Azure Service Bus Data Sender | Service Bus namespace | Publish meal reminders (diet-service) |
| Azure Service Bus Data Receiver | Service Bus namespace | Consume messages (notification-service) |

---

### 3. Self-Hosted Runner Identity
**Type:** System-Assigned Managed Identity on the Azure VM running GitHub Actions
**Why it exists:** The CI/CD pipeline needs to run `terraform apply` — which means it needs full Azure access to create/modify resources. Instead of storing Azure credentials as GitHub Secrets, the runner VM authenticates using its built-in identity. No secrets ever leave Azure.

**Roles granted (set up manually once):**
| Role | Scope | Reason |
|---|---|---|
| Contributor | Subscription or Resource Group | Allow Terraform to create all resources |
| Key Vault Secrets User | Bootstrap Key Vault | Fetch sensitive tfvars at pipeline runtime |
| Storage Blob Data Contributor | tfstate Storage Account | Read/write Terraform remote state |

---

## Resources Created and How They Connect

```
┌─────────────────────────────────────────────────────────────┐
│                    Resource Group                           │
│                                                             │
│  ┌────────────────── VNet (10.x.0.0/16) ────────────────┐  │
│  │                                                       │  │
│  │  appgw-subnet ──► Application Gateway ◄── Internet   │  │
│  │       │                                               │  │
│  │  aks-subnet   ──► AKS Cluster                        │  │
│  │       │               │                               │  │
│  │       │          Pods (Workload Identity)             │  │
│  │       │               │                               │  │
│  │  db-subnet    ──► PostgreSQL Flexible Server          │  │
│  │                       │                               │  │
│  │  ep-subnet    ──► Private Endpoints                   │  │
│  │                    ├── Key Vault                      │  │
│  │                    └── (other services)               │  │
│  │                                                       │  │
│  │  vm-subnet    ──► Jump VM ◄── NAT Gateway             │  │
│  │                                                       │  │
│  │  AzureBastionSubnet ──► Azure Bastion                 │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  Key Vault ──► CSI Driver ──► K8s Secrets ──► Pods         │
│  Service Bus ──► Workload Identity ──► diet/notification    │
│  ACR ──► AKS (AcrPull via Cluster Identity)                │
│  Log Analytics + App Insights ──► All resources            │
│  Bastion ──► Jump VM (no public IP on VM)                  │
└─────────────────────────────────────────────────────────────┘
```

### Resource Inventory

| Resource | Name Pattern | Purpose |
|---|---|---|
| Resource Group | `nutriai-rg-<env>` | Container for all resources |
| Virtual Network | `nutriai-vnet-<env>` | Private network fabric |
| NSGs (5) | `nutriai-*-nsg-<env>` | Subnet-level traffic control |
| Route Table | `nutriai-aks-rt-<env>` | AKS egress routing |
| NAT Gateway | `nutriai-nat-gw-<env>` | Outbound internet for VM subnet |
| AKS Cluster | `var.aks_cluster_name` | Kubernetes control plane |
| Azure Container Registry | `var.acr_name` | Docker image registry |
| PostgreSQL Flexible | `nutriai-postgres-<env>` | Application database |
| Key Vault | `var.keyvault_name` | Application secrets + KV CSI |
| Service Bus (Standard) | `nutriai-sb-<env>` | Async messaging (meal reminders) |
| Service Bus Topic | `email-notifications` | Message topic |
| Service Bus Subscription | `email-sender` | Consumer subscription |
| Azure OpenAI | `nutriai-openai-<env>` | Diet plan generation (GPT-5.1) |
| Document Intelligence | `nutriai-docintel-<env>` | Medical document OCR |
| Application Gateway | `nutriai-appgw-<env>` | L7 ingress + WAF |
| Bastion Host | `nutriai-bastion-<env>` | Secure VM access |
| Jump VM | `nutriai-vm-<env>` | Admin/debug access |
| Log Analytics Workspace | `nutriai-logs-<env>` | Centralized logging |
| Application Insights | `nutriai-appinsights-<env>` | APM + distributed tracing |
| Workload Identity | `nutriai-workload-identity-<env>` | Pod authentication |
| AKS Cluster Identity | `nutriai-aks-identity-<env>` | Cluster-level Azure access |

### Key Vault Secrets Written by Terraform

| Secret Name | Value Source |
|---|---|
| `database-url` | Assembled from postgres module outputs |
| `jwt-secret-key` | `random_string` resource (32 chars) |
| `entra-client-id` | `var.entra_client_id` |
| `entra-tenant-id` | `var.entra_tenant_id` |
| `entra-client-secret` | Placeholder (Workload Identity used in prod) |
| `azure-storage-connection-string` | From pre-existing Storage Account data lookup |
| `azure-openai-endpoint` | From `module.openai` output |
| `azure-openai-key` | From `module.openai` output |
| `azure-document-intelligence-endpoint` | From `module.document_intelligence` output |
| `azure-document-intelligence-key` | From `module.document_intelligence` output |
| `smtp-username` | `var.smtp_username` |
| `smtp-password` | `var.smtp_password` |
| `applicationinsights-connection-string` | From `module.monitoring` output |

---

## How the Pipeline Works

```
git push → main branch          git push → dev branch
       │                                  │
       ▼                                  ▼
runs-on: [self-hosted, nutriai-prod]  runs-on: [self-hosted, nutriai-dev]
       │                                  │
       ▼                                  ▼
┌──────────────────────────────────────────────────────┐
│  1. Checkout code                                    │
│  2. Set ENV_NAME=prod/dev, TFVARS_FILE, backend key  │
│  3. Install Terraform 1.9.0                          │
│  4. az login --identity  (Managed Identity — no pw)  │
│  5. Fetch secrets from Bootstrap KV:                 │
│       postgres_admin_password → TF_VAR_*             │
│       vm_admin_password       → TF_VAR_*             │
│       smtp_password           → TF_VAR_*             │
│       (masked in logs immediately)                   │
│  6. terraform fmt -check -recursive                  │
│  7. terraform init -backend-config key=<env>.tfstate │
│  8. terraform validate                               │
│  9. terraform plan -var-file=environments/<env>/...  │
│ 10. Post plan output as PR comment (on PRs only)     │
│ 11. terraform apply (on push to main/dev only)       │
│     ← gated by GitHub Environment approval for prod  │
└──────────────────────────────────────────────────────┘
```

### Branch → Environment Mapping

| Git Branch | Environment | Runner Label | tfvars File | Backend Key |
|---|---|---|---|---|
| `main` | prod | `nutriai-prod` | `environments/prod/terraform.tfvars` | `nutriai-prod.tfstate` |
| `dev` | dev | `nutriai-dev` | `environments/dev/terraform.tfvars` | `nutriai-dev.tfstate` |

### Pull Request Flow
- On PR to `main` or `dev`: runs fmt check + init + validate + plan
- Plan output is posted automatically as a PR comment
- `terraform apply` does **not** run on PRs

### Manual Trigger
Use **Actions → Run workflow → action=apply** to apply outside of a push.

---

## How the Self-Hosted Runner Gets Authenticated

The runner VM uses its **System-Assigned Managed Identity** — no credentials are stored anywhere.

### Step 1: Runner VM setup (one-time)
```bash
# On the Azure VM that will run GitHub Actions:
# 1. Enable System-Assigned Managed Identity in Azure Portal
#    VM → Identity → System Assigned → On

# 2. Assign required roles (run once by an admin):
RUNNER_IDENTITY=$(az vm show --name <runner-vm-name> \
  --resource-group <runner-rg> \
  --query "identity.principalId" -o tsv)

# Contributor on the target subscription (for Terraform)
az role assignment create \
  --assignee $RUNNER_IDENTITY \
  --role "Contributor" \
  --scope "/subscriptions/<subscription-id>"

# Storage Blob Data Contributor (for tfstate)
az role assignment create \
  --assignee $RUNNER_IDENTITY \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<tfstate-sa>"

# 3. Configure GitHub Action Secrets
# Configure the following secrets in your GitHub Repository settings (or Environment Secrets):
#   - POSTGRES_ADMIN_PASSWORD
#   - VM_ADMIN_PASSWORD
#   - SMTP_USERNAME
#   - SMTP_PASSWORD
#   - ENTRA_TENANT_ID
#   - ENTRA_CLIENT_ID
#   - ENTRA_CLIENT_SECRET
#   - ENTRA_REDIRECT_URI

```

### Step 3: Register the runner
```bash
# On the runner VM, register with GitHub:
mkdir actions-runner && cd actions-runner
curl -L https://github.com/actions/runner/releases/download/v2.x.x/actions-runner-linux-x64-2.x.x.tar.gz | tar xz

# For prod runner:
./config.sh --url https://github.com/<org>/<repo> \
  --token <registration-token> \
  --labels "self-hosted,nutriai-prod" \
  --name "nutriai-prod-runner"

./svc.sh install && ./svc.sh start

# For dev runner (separate VM):
./config.sh --url https://github.com/<org>/<repo> \
  --token <registration-token> \
  --labels "self-hosted,nutriai-dev" \
  --name "nutriai-dev-runner"
```

### Step 4: Pipeline auth flow
```
GitHub Actions job starts on runner VM
  │
  ▼
GitHub decrypts secrets & passes them to job environment (TF_VAR_*)
  │
  ▼
az login --identity
  │  uses Azure IMDS endpoint (http://169.254.169.254)
  │  no credentials needed — identity is attached to VM
  ▼
terraform init / plan / apply
  │  uses the same managed identity for ARM API calls
  │  uses same identity for Storage Account backend access
  ▼
Azure resources created/updated (Key Vault secrets created directly)
```

---

## How to Run Terraform Manually

### Prerequisites
- Azure CLI installed and logged in: `az login`
- Terraform >= 1.9.0: `terraform -version`
- Access to the Bootstrap Key Vault to retrieve sensitive values

### Steps

```bash
cd NutriAI-terraform

# 1. Set sensitive values in your local environment
export TF_VAR_postgres_admin_password="your-secure-postgres-password"
export TF_VAR_vm_admin_password="your-secure-vm-password"
export TF_VAR_smtp_username="your-smtp-username"
export TF_VAR_smtp_password="your-smtp-password"
export TF_VAR_entra_tenant_id="your-entra-tenant-id"
export TF_VAR_entra_client_id="your-entra-client-id"
export TF_VAR_entra_client_secret="your-entra-client-secret"
export TF_VAR_entra_redirect_uri="your-entra-redirect-uri"

# 2. Init with the correct backend key
# For prod:
terraform init -backend-config="key=nutriai-prod.tfstate"
# For dev:
terraform init -backend-config="key=nutriai-dev.tfstate"

# 3. Validate
terraform validate

# 4. Plan
terraform plan -var-file="environments/prod/terraform.tfvars"
# or for dev:
terraform plan -var-file="environments/dev/terraform.tfvars"

# 5. Apply
terraform apply -var-file="environments/prod/terraform.tfvars"
```

---

## Values to Update in K8s Manifests After Apply

After `terraform apply` completes, run these commands and update the manifests:

```bash
# Get outputs
WORKLOAD_IDENTITY_CLIENT_ID=$(terraform output -raw workload_identity_client_id)
KEYVAULT_NAME=$(terraform output -raw keyvault_name)
SERVICE_BUS_FQDN=$(terraform output -raw service_bus_fqdn)
TENANT_ID="<your entra_tenant_id from tfvars>"

echo "Workload Identity Client ID : $WORKLOAD_IDENTITY_CLIENT_ID"
echo "Key Vault Name              : $KEYVAULT_NAME"
echo "Service Bus FQDN            : $SERVICE_BUS_FQDN"
```

### Files to update

#### `k8s/<env>/service-account.yaml`
```yaml
annotations:
  azure.workload.identity/client-id: "<WORKLOAD_IDENTITY_CLIENT_ID>"  # ← replace
```

#### `k8s/<env>/secret-provider.yaml` (all 8 SecretProviderClass objects)
```yaml
parameters:
  clientID: "<WORKLOAD_IDENTITY_CLIENT_ID>"   # ← replace
  keyvaultName: "<KEYVAULT_NAME>"             # ← replace
  tenantId: "<TENANT_ID>"                     # ← replace
```

#### `k8s/<env>/configmaps.yaml`
```yaml
# diet-service-config:
AZURE_SERVICE_BUS_FULLY_QUALIFIED_NAMESPACE: "<SERVICE_BUS_FQDN>"  # ← replace if different

# notification-service-config:
AZURE_SERVICE_BUS_FULLY_QUALIFIED_NAMESPACE: "<SERVICE_BUS_FQDN>"  # ← replace if different
```

#### `k8s/<env>/ingress.yaml`
```yaml
spec:
  rules:
    - host: "<your-actual-domain.com>"   # ← replace nutriai.example.com
```

---

## Bootstrap Setup (One-Time)

Before the first pipeline run, a one-time manual setup is needed:

```bash
# 1. Create tfstate Storage Account
az group create -n nutriai-manual-rg -l eastus
az storage account create -n nutriaimtfstatestore -g nutriai-manual-rg -l eastus --sku Standard_LRS
az storage container create -n tfstate --account-name nutriaimtfstatestore

# 2. Add sensitive variables to GitHub Repository/Environment Secrets (see "Runner Authentication" section)


# 4. Register GitHub Actions self-hosted runners (see "Runner Authentication" section)

# 5. Create GitHub Environments in repo settings:
#    - "production"  → require manual approval before apply
#    - "development" → no approval required

# 6. Fill real values in terraform.tfvars (entra IDs, storage account names)
#    Then commit and push to trigger the pipeline.
```
