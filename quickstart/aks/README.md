# Edge Integration Cell quickstart on Azure Kubernetes Service (AKS)

> [!IMPORTANT]
> Always verify latest stable AKS version supported by SAP.

## Choose your preferred way to provision AKS

1. Local machine with installed Terraform
2. Azure Cloud Shell with built-in Terraform
3. Provided Devcontainer with built-in Terraform

- Clone the repository to your local machine/cloud shell:

```bash
git clone https://github.com/Azure/sap-edge-integration-cell-on-azure-accelerator.git
cd sap-edge-integration-cell-on-azure-accelerator/quickstart/aks
```

> [!TIP]
> Set your subscription explicitly in the Azure CLI. This is important to avoid confusion with other subscriptions you might have access to.
>
> ```bash
> az account set --subscription <your_subscription_id>
> ```

> [!TIP]
> Skip ARM provider registration by terraform by setting variable $env:ARM_SKIP_PROVIDER_REGISTRATION="true";

### 1. Use local with installed Terraform

If you already have an existing installation of Terraform, you can use the provided scripts to accelerate the provisioning of needed AKS resources for Edge Integration Cell. You can also use [SAP Scripts](../sap/README.md) to enable the entitlements on BTP.

### 2. Use Cloud Shell with built-in terraform

The easiest way to provision an AKS-Cluster is to use Cloud Shell. With Cloud Shell you do not need to install any additional software. Everything you need is included.
Cloud Shell can be reached via [Azure Portal](https://portal.azure.com) or [directly from here](https://shell.azure.com).

### 3. Use provided Devcontainer

This is very similar to 1. Build local with installed Terraform without need of installation and configuration of Terraform. All dependencies are managed by devcontainer. Steps and Commands are similar for provisioning inside devcontaier with Terraform.

## Terraform commands

Once you made your choice, you can use the provided scripts to provision the AKS cluster.

The following table shows all parameters and a brief description for usage.

|Parameter|Description|
|---|---|
|resource_group_name|Name of the Resource Group where the AKS Cluster should be deployed to|
|location|Location of Resources (default: `swedencentral`). Prefer less congested regions like `swedencentral` for better quota availability.|
|kubernetes_version|Kubernetes version for the AKS cluster (default: `1.34`). Verify latest SAP-supported version before deploying.|
|node_count|Number of nodes in the default node pool (default: `2`)|
|vm_size|VM size for default node pool nodes (default: `Standard_D8ds_v5`). Must meet SAP EIC minimum requirements (8 vCPU, 32 GB RAM).|

Create and save the following lines to a local file named terraform.tfvars to simply store parameter values for your environment. You can set your own values based on requirements.

```text
resource_group_name = "eic-on-azure"
location = "swedencentral"
```

### 1. Initialize dependencies and providers

```bash
terraform init
```

### 2. Preview changes

```bash
terraform plan
```

### 3. Commit changes to current state

```bash
terraform apply
```

## Post AKS Provisioning

The deployment created the required Kubernetes infrastructure for SAP Edge Integration Cell.

- Consider deploying SAP Integration Suite with Edge Integration Cell entitlement using the [SAP BTP Terraform Provider](../sap/README.md) to automate the deployment of the required service.

**This accelerator intentionally stops after Azure provisioning and handover to SAP Integration Suite.**
**For SAP-specific EIC installation steps in ELM and Integration Suite, follow SAP's always up-to-date guidance: [SAP Reference Architecture](https://architecture.learning.sap.com/docs/ref-arch/263f576c90/2) and [SAP installation video](https://www.youtube.com/watch?v=PHPPnma7Y1A).**

> [!TIP]
> See [ELM Configuration Hints](../../knowledge-base/elm-configuration.md) for recommended ELM wizard settings (storage classes, registry config, proxy, etc.) — covers both POC and production scenarios.

> [!WARNING]
> Re-running ELM setup with the same runtime display name and edge node identity can cause status conflicts (for example during key store creation) if dangling processes from a previous run still exist. Before retrying, clean up failed/partial artifacts and use fresh runtime/node names where possible.

Further down you will find supporting commands not mentioned in the video.

### Get kubeconfig file

- Retrieve the kubeconfig file to connect to the AKS cluster. You can use the following command to get the kubeconfig file from Cloud Shell:

```bash
az aks get-credentials --resource-group <resource_group_name> --name <name_of_aks_cluster>
```

- Browse to your local `.kube` directory. On Windows, this is usually located at `C:\Users\<your_username>\.kube\config`. On Linux or MacOS, it is usually located at `~/.kube/config`.
- Open the `config` file and verify the cluster name and context. Keep note of the name. You will need to select it during the installation of Edge Integration Cell on upload of the config file.

### Get istio ingress gateway IP address for DNS mapping

- Collect the IP address of the istio ingress gateway. You can use the following command to get the IP address:

```bash
kubectl -n istio-system get service istio-ingressgateway
```

Or find it on the Azure Portal under the `Kubernetes Resources` section in step `Services and Ingresses`. The IP address is listed under the `Cluster-IP` column.

- For host mapping, you can either use your own DNS entry or, for temporary PoC testing, use `nip.io` (`<ingress-ip>.nip.io`, for example `20.91.10.10.nip.io`).
- For long-lived or production deployments, use a proper DNS entry with your own domain and certificate management.

- Take note of it to craft your integration flow endpoint URL. Examples: `https://eic.example.com/http/smokeTest` or `https://<ingress-ip>.nip.io/http/smokeTest`.

### Smoke test

A ready-made SAP CPI integration package is included for quick validation:

1. **Import** the [Azure Quickstart for EIC](./Azure%20Quickstart%20for%20EIC.zip) package into SAP Integration Suite (Design → Import)
2. **Deploy** the integration flow to your Edge Integration Cell runtime. See SAP's guide: [Deploy Integration Content to Edge Integration Cell](https://help.sap.com/docs/integration-suite/sap-integration-suite/deploying-integration-content-on-edge-integration-cell)
3. **Test** using the service key of your Process Integration Runtime:

```bash
curl -k --user "<clientid>:<clientsecret>" https://<host>/http/smokeTest
```

> [!TIP]
> Use `-k` only for temporary test scenarios where certificate validation is intentionally bypassed. For production, configure a valid TLS certificate via cert-manager.
