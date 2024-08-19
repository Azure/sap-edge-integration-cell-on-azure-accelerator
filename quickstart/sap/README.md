# Edge Integration Cell quickstart with SAP BTP terraform provider

The SAP BTP terraform provider allows you to manage resources in SAP Business Technology Platform (BTP) using Terraform. Verify the latest capabilities and limitations of the provider in the [official documentation](https://registry.terraform.io/providers/SAP/btp/latest/docs). The scripts in this repos support the creation of the entitlements and scaffolding resources required for the Edge Integration Cell (EIC) on SAP BTP initially.

The is part of the repos serves as the stepping stone towards a fully integrated deployment experience across SAP BTP and Azure. As more features in the SAP BTP provider are released, the scripts will be updated.

## Setup

You need to set the following Environment Variables:

|Name|Description|
|---|---|
|BTP_USERNAME|The Username to access SAP BTP|
|BTP_PASSWORD|The Password to access SAP BTP|

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
