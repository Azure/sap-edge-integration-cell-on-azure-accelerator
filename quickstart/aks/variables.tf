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
  description = "The number of nodes for the default node pool."
  type        = number
  default     = 2
}