# Edge Integration Cell quickstart on Azure Kubernetes Service (AKS)

> [!IMPORTANT]
> Always verify latest stable AKS version supported by SAP.
> Successfully Tested with Version=1.28.10

## Choose your preferred way to provision AKS

1. Local machine with installed Terraform
2. Azure Cloud Shell with built-in Terraform
3. Provided Devcontainer with built-in Terraform

- Clone the repository to your local machine/cloud shell:

```bash
git clone https://github.com/Azure/sap-edge-integration-cell-on-azure-accelerator.git
cd sap-edge-integration-cell-on-azure-accelerator/quickstart/aks
```

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
|location|Location of Resources (e.g. westeurope, swedencentral)|

Create and save the following lines to a local file named aks.tfvars to simply store parameter values for your environment. You can set your own values based on requirements.

```text
resource_group_name = "eic-on-azure"
location = "westeurope"
```

### 1. Initialize dependencies and providers

```bash
terraform init
```

### 2. Preview changes

```bash
terraform plan -var-file="aks.tfvars"
```

### 3. Commit changes to current state

```bash
terraform apply -var-file="aks.tfvars"
```

## Post AKS Provisioning

The deployment created the required Kubernetes infrastructure for SAP Edge Integration Cell.

- Consider deploying SAP Integration Suite with Edge Integration Cell entitlement using the [SAP BTP Terraform Provider](../sap/README.md) to automate the deployment of the required service.

**Continue with SAP's [manual installation guide](https://www.youtube.com/watch?v=PHPPnma7Y1A) because not all steps are automated yet.**

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

- Create a DNS entry for the IP address. You can use any DNS provider to create a DNS entry. Apply it as virtual host in the Edge Integration Cell configuration. The DNS entry should point to the IP address of the istio ingress gateway. For example, you can create a DNS entry like `eic.example.com` and point it to the IP address of the istio ingress gateway.

- Take note of it to craft your integration flow endpoint URL. For example, if you created a DNS entry like `eic.example.com`, the integration flow endpoint URL with http trigger for your "smoke test" would be `https://eic.example.com/http/integration-smoke-test`.

### Smoke test

- Create a new integration flow in the SAP Integration Suite with http trigger
- Deploy it to your newly available Edge Integration Cell runtime
- Use the service key of your process integration runtime to send a test message to the integration flow `GET https://eic.example.com/http/integration-smoke-test`
