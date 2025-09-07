# Terraform Module: networks
# vim: set expandtab ts=2 sw=2 ft=terraform:
#
#
# Access Network (Bastion Hosts)
/*
# THIS DOES NOT WORK
#   getting errors when referencing from parent:
#     base_pool.name = "myname"
variable "access_network" {
  description = "Network configuration for jump hosts"
  type = object({
    addresses     = list(string)
    domain        = string
    external_addr = string
    external_dns  = string
  })
  default = {
    addresses     = ["127.31.255.0/29"]
    domain        = "your-domain-for-dfir.org"
    external_addr = "192.168.0.1"
    external_dns  = "8.8.8.8"
  }
}
*/
variable "access_network_addresses" {
  description = "Network configuration for jump hosts: addresses"
  type        = list(string)
}
variable "access_network_domain" {
  description = "Network configuration for jump hosts: domain"
  type        = string
}
variable "access_network_external_addr" {
  description = "Network configuration for jump hosts: external_addr"
  type        = string
}
variable "access_network_external_dns" {
  description = "Network configuration for jump hosts: external_dns"
  type        = string
}
variable "access_network_external_forwarders" {
  description = "Network configuration for jump hosts: forwarders"
  type        = map(string)
  /*
  default = {
      "ir-submarine-20250327.your-domain-for-dfir.org" = "10.177.0.1"
      "ir-battleship-20250803.your-domain-for-dfir.org" = "10.177.2.1"
  }
  */
}
//domain  = local.case_network_domain
//address = local.case_network_localdns
