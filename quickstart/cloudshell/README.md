# AKS Deployment via Cloud Shell

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
> Tested with 1.28.10

## Command
Replace your values within <...>

```bash
az aks create --name <name_of_aks_cluster> --resource-group <resource_group_name> --load-balancer-sku standard --location <location_name> --kubernetes-version <1.28.10> --node-vm-size Standard_D4ds_v5 --tier free --generate-ssh-keys
```