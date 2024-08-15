# Edge Integration Cell quickstart on Azure Kubernetes Service (AKS)

## 1. Use local with installed Terraform
If you already have an existing installation of Terraform, you can use the provided scripts to accelerate the provisioning of needed AKS resources for Edge Integration Cell. You can also use [SAP Scripts](sap/README.md) to enable the entitlements on BTP.

### Commands
Provided Scripts are using parameters. The following table shows all parameters and a brief description for usage.

|Parameter|Description|
|---|---|
|resource_group_name|Name of the Resource Group where the AKS Cluster should be deployed to|
|location|Location of Resources (e.g. westeurope, swedencentral)|

Create and save the following lines to a local file named aks.tfvars to simply store parameter values for your environment. You can set your own values based on requirements.

```text
resource_group_name = "eic-on-azure"
location = "westeurope"
```

#### 1. Initialize dependencies and providers
```bash
terraform init
```

#### 2. Preview changes
```bash
terraform plan -var-file="aks.tfvars"
```

#### 3. Commit changes to current state
```bash
terraform apply -var-file="aks.tfvars"
```

## 2. Use Cloud Shell

The easiest way to provision an AKS-Cluster is to use Cloud Shell. With Cloud Shell you do not need to install any additional software. Everything you need is included.
Cloud Shell can be reached via [Azure Portal](https://portal.azure.com) or [directly from here](https://shell.azure.com).

|Parameters|Description|
|---|---|
|--name | Name of the AKS Cluster|
|--resource-group| Name of the Resource Group where the AKS Cluster should be deployed to |
|--load-balancer-sku | SKU of Load Balancer (standard is good to quickstart) |
|--location | Location of Resources (e.g. westeurope, swedencentral)|
|--kubernetes-version | Version of Kubernetes to deploy |
|--node-vm-size | Size of Node VM |
|--tier | SKU of AKS Service |
|--generate-ssh-keys | Provide if you wish to create SSH-Keys automatically. Otherwise you need to specify keys.|

## Kubernetes Version
> [!IMPORTANT]
> Always verify latest stable AKS version supported by SAP.
> Successfully Tested with Version=1.28.10

## Command
Replace your values within <...>

```bash
az aks create --name <name_of_aks_cluster> --resource-group <resource_group_name> --load-balancer-sku standard --location <location_name> --kubernetes-version <1.28.10> --node-vm-size Standard_D4ds_v5 --tier free --generate-ssh-keys
```
## 3. Use provided Devcontainer

This is very similar to 1. Build local with installed Terraform without need of installation and configuration of Terraform. All dependencies are managed by devcontainer. Steps and Commands are similar for provisioning inside devcontaier with Terraform.


