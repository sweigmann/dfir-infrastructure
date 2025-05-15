# Terraform Variable declarations
# vim: set expandtab ts=2 sw=2 ft=terraform:
#
# Provider Configuration
variable "libvirt_config" {
  description = "Select the virtualization technology for your project and provide a connection string"
  type = object({
    name = string
    uri  = string
  })
  default = {
    name = "example"
    uri  = "http://example.com"
  }
}
#
#
# Case Configuration
variable "case_config" {
  description = "A case type, codename and the date when it started"
  type = object({
    type = string
    code = string
    date = string
  })
  default = {
    type = "ir"
    code = "doublesanta"
    date = "20241225"
  }
}
#
#
# User Configuration
variable "user_config" {
  description = "This holds a user's config"
  type = object({
    username  = string
    usergecos = string
    password  = string
    ssh_key   = string
  })
}
#
#
# Pool Configurations
#
# Base Image Pool
variable "base_pool_config" {
  description = "Storage pool for base images"
  type = object({
    name = string
    path = string
  })
  default = {
    name = "base_images"
    path = "/var/lib/libvirt/images/base_images"
  }
}
#
# DFIR Pool
variable "dfir_pool_config" {
  description = "Storage pool name and path for DFIR nodes"
  type = object({
    name = string
    base_path = string
  })
  default = {
    name = "dfir_images"
    base_path = "/var/lib/libvirt/images/dfir"
  }
}
#
#
# Network Configuration
#
# Access Network
variable "access_network" {
  description = "Network configuration for jump hosts"
  type = object({
    addresses = list(string)
    domain = string
    external_addr = string
    external_dns = string
  })
  default = {
    addresses = [ "127.31.255.0/29" ]
    domain = "your-domain-for-dfir.org"
    external_addr = "192.168.0.1"
    external_dns = "8.8.8.8"
  }
}
#
# Case Network
variable "case_network" {
  description = "Network configuration for this case"
  type = object({
    network_addr = string
    network_cidr = string
  })
  default = {
    network_addr = "10.10.10.0"
    network_cidr = "24"
  }
}
#
#
# Tags and versions for software
variable "software_tags" {
  description = "Tags and versions for software to be installed"
  type = object({
    plaso = string
    timesketch = string
    ts_notebook = string
  })
  default = {
    plaso         = "20241006"
    timesketch    = "20241129"
    ts_notebook   = "sha256:4ca1d875c49b3e8ba2fa55d3776bcbd586b9dcf8a3537db4dcc6c07e8f5c3844"
  }
}
