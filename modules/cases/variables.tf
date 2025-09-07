# Terraform Module: cases
# vim: set expandtab ts=2 sw=2 ft=terraform:
#
#
# Case ID
variable "case_id" {
  description = "Case ID in the form type-codeword-date (i.e. ir-sasquatch-20240615)"
  type        = string
}
#
# Network Configuration
variable "access_nwk_domain" {
  description = "FQDN for the access network"
  type        = string
}
variable "access_nwk_dns" {
  description = "IP address for a name server"
  type        = string
}
variable "access_nwk_id" {
  description = "Access network ID"
  type        = string
}
variable "nwk_addr" {
  description = "Base address for the case network (i.e. 192.168.20.0)"
}
variable "nwk_cidr" {
  description = "CIDR range for the case network (i.e. 24)"
  type        = string
}
#
# Software Versions
variable "sw_alpine_release" {
  description = "Release information for Alpine Linux"
  type        = string
}
variable "sw_debian_release" {
  description = "Release information for Debian Linux"
  type        = string
}
variable "plaso_version" {
  description = "Git Tag for Plaso"
  type        = string
}
variable "timesketch_version" {
  description = "Git Tag for Timesketch"
  type        = string
}
variable "notebook_version" {
  description = "Docker Tag for the Timesketch Notebook"
  type        = string
}
#
# Pools
variable "base_image_pool_id" {
  description = "Pool id for the Base Images pool"
  type        = string
}
variable "dfir_pool_base_path" {
  description = "Path under which the case pool should be created"
  type        = string
}
#
# Images
variable "sw_alpine_image_id" {
  description = "Volume id for the Alpine Linux image"
  type        = string
}
variable "sw_debian_image_id" {
  description = "Volume id for the Debian Linux image"
  type        = string
}
#
# Disk Volumes
variable "bastion_root" {
  description = "Root volume size for the bastion host"
  type        = number
}
variable "gateway_root" {
  description = "Root volume size for the gateway"
  type        = number
}
variable "worker_root" {
  description = "Root volume size for the worker host"
  type        = number
}
variable "worker_data" {
  description = "Data volume size for the worker host"
  type        = number
}
variable "siftstation_root" {
  description = "Root volume size for the siftstation"
  type        = number
}
#
# Users
variable "users_case_vms" {
  description = "File with user configurations for case VMs"
  type        = string
}
variable "users_gateway" {
  description = "File with user configurations for the gateway"
  type        = string
}
