###
# Assumption SAP CPI is already available in Subaccount
###
 
resource "btp_subaccount_entitlement" "cpi_edge_integration_cell" {
  subaccount_id = var.subaccount_id
  service_name  = "integration_suite"
  plan_name     = "edge_integration_cell"
}