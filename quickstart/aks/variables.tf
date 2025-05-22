variable "resource_group_name" {
  description = "A prefix used for all resources in this example"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be provisioned"
}

variable "node_count" {
  description = "The number of nodes for the default node pool."
  type        = number
  default     = 2
}