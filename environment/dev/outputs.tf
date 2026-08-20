output "hub_vnet_id" {
  description = "Resource ID of the Hub VNet"
  value       = module.hub_network.vnet_id
}

output "hub_subnets" {
  description = "Map of all subnet IDs in the Hub VNet"
  value       = module.hub_network.subnet_ids
}

output "spoke_vnet_id" {
  description = "Resource ID of the Spoke VNet"
  value       = module.spoke_network.vnet_id
}

output "spoke_subnets" {
  description = "Map of all subnet IDs in the Spoke VNet"
  value       = module.spoke_network.subnet_ids
}