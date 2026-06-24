variable "resource_group_name" {
  description = "A prefix used for all resources in this example"
}

variable "location" {
  description = "The Azure Region in which all resources should be provisioned. Prefer less congested regions (e.g. swedencentral) over high-demand ones (e.g. westeurope, eastus) for faster provisioning and better quota availability."
  type        = string
  default     = "swedencentral"
}

variable "kubernetes_version" {
  description = "The Kubernetes version for the AKS cluster. Verify latest stable version supported by SAP before deploying."
  type        = string
  default     = "1.34"
}

variable "node_count" {
  description = "The number of nodes in the default node pool."
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "The VM size for nodes in the default node pool. Standard_D8ds_v5 meets SAP EIC minimum requirements (8 vCPU, 32 GB RAM)."
  type        = string
  default     = "Standard_D8ds_v5"
}