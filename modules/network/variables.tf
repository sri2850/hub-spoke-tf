variable "vnet_name" {
    type = string
}
variable "address_space" {
    type = list(string)
}
variable "resource_group_name" {
  type = string
}
variable "location" {
    type = string
}
variable "subnets" {
    type = map(object({
      address_prefixes = list(string)
      service_endpoints = optional(list(string), [])
      private_endpoint_network_policies             = optional(string, "Enabled")
    private_link_service_network_policies_enabled = optional(bool, true)
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = optional(list(string), ["Microsoft.Network/virtualNetworks/subnets/action"])
    }))
  }))
  default = {}
}

variable "tags" {
  description = "A mapping of tags to assign to the resources."
  type        = map(string)
  default     = {}
}