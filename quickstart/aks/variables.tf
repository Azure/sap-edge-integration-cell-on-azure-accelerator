variable "resource_group_name" {
  description = "A prefix used for all resources in this example"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be provisioned"
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