variable "default_location" {
  type = string
  description = "The Default Location of Resources"
}

variable "resource_group_name" {
  type = string
  description = "The Name of the Resource Group which contains the needed Resources"
}

variable "node_count" {
  type        = number
  description = "The initial quantity of nodes for the node pool."
  default     = 2
}

variable "msi_id" {
  type        = string
  description = "The Managed Service Identity ID. Set this value if you're running this example using Managed Identity as the authentication method."
  default     = null
}

variable "username" {
  type        = string
  description = "The admin username for the new cluster."
  default     = "azureadmin"
}

variable "name_prefix" {
  default     = "postgresqlfs"
  description = "Prefix of the resource name."
}