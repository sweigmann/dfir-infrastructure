# Terraform Main
# vim: set expandtab ts=2 sw=2 ft=terraform:
#
# Provider Configuration
provider "libvirt" {
  uri = var.libvirt_config.uri
}
#
#
# Local Variables
locals {
}
#
#
# Pools
#
# Base Image Pool
module "base_image_pool" {
  source                           = "./modules/images"
  base_pool_name                   = var.base_pool_config.name
  base_pool_path                   = var.base_pool_config.path
  base_pool_type                   = var.base_pool_config.type
  base_image_alpine_v3_name        = var.bi_alpine.name
  base_image_alpine_v3_release     = var.bi_alpine.release
  base_image_alpine_v3_format      = var.bi_alpine.format
  base_image_alpine_v3_source      = var.bi_alpine.source
  base_image_debian_trixie_name    = var.bi_debian.name
  base_image_debian_trixie_release = var.bi_debian.release
  base_image_debian_trixie_format  = var.bi_debian.format
  base_image_debian_trixie_source  = var.bi_debian.source
}
#
#
# Networks
#
# Access Network (Bastion Hosts and Gateways)
module "access_network" {
  source                       = "./modules/networks"
  access_network_addresses     = var.access_network.addresses
  access_network_domain        = var.access_network.domain
  access_network_external_addr = var.access_network.external_addr
  access_network_external_dns  = var.access_network.external_dns
  access_network_external_forwarders = {
    for c in var.cases :
    "${c.case_type}-${c.case_code}-${c.case_date}.${var.access_network.domain}" => cidrhost("${c.network_addr}/${c.network_cidr}", 1)
  }
}
#
#
# Cases
#
# Case module
module "case" {
  source              = "./modules/cases"
  for_each            = { for c in var.cases : "${c.case_type}-${c.case_code}-${c.case_date}" => c }
  case_id             = each.key
  nwk_addr            = each.value.network_addr
  nwk_cidr            = each.value.network_cidr
  plaso_version       = each.value.software_plaso
  vol3_version        = each.value.software_vol3
  timesketch_version  = each.value.software_timesketch
  notebook_version    = each.value.software_notebook
  iris_version        = each.value.software_iris
  bastion_root        = each.value.volsize_bastion_root
  gateway_root        = each.value.volsize_gateway_root
  worker_root         = each.value.volsize_worker_root
  worker_data         = each.value.volsize_worker_data
  iris_root           = each.value.volsize_iris_root
  siftstation_root    = each.value.volsize_siftstation_root
  dfir_pool_base_path = var.dfir_pool_config.base_path
  access_nwk_domain   = var.access_network.domain
  access_nwk_dns      = var.access_network.external_dns
  access_nwk_id       = module.access_network.access_network_id
  base_image_pool_id  = module.base_image_pool.pool_id
  sw_alpine_release   = module.base_image_pool.volume_alpine_v3_release
  sw_debian_release   = module.base_image_pool.volume_debian_trixie_release
  sw_alpine_image_id  = module.base_image_pool.volume_alpine_v3_id
  sw_debian_image_id  = module.base_image_pool.volume_debian_trixie_id
  users_case_vms      = "${path.module}/users-case-vms.json"
  users_gateway       = "${path.module}/users-gateway.json"
}
