output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}
output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}
output "vnet_address_space" {
  description = "The address space list of the VNet."
  value       = azurerm_virtual_network.vnet.address_space
}
output "subnet_ids" {
  value = {
    for key, subnet in azurerm_subnet.this : key => subnet.id
  }
}