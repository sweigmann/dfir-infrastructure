# Terraform Variable Declarations
# vim: set expandtab ts=2 sw=2 ft=terraform:
#
# Provider Configuration
variable "libvirt_config" {
  description = "Provide a QEMU/KVM connection string"
  type = object({
    name = string
    uri  = string
  })
  default = {
    name = "example"
    uri  = "qemu:///system"
    #uri  = "qemu+ssh://user@remote-host/system?keyfile=id_ssh_keyfile"
  }
}
#
#
# Case Configuration (with examples)
variable "cases" {
  description = "List of all cases with their configurations"
  type = list(object({
    # Case Identifier
    case_type = string
    case_code = string
    case_date = string
    # Case Network
    network_addr = string
    network_cidr = string
    # Tags and versions for software
    software_plaso      = string
    software_vol3       = string
    software_timesketch = string
    software_notebook   = string
    software_iris       = string
    # Volume sizes (in Bytes)
    volsize_bastion_root     = number
    volsize_gateway_root     = number
    volsize_worker_root      = number
    volsize_worker_data      = number
    volsize_iris_root        = number
    volsize_siftstation_root = number
  }))
  /*
  default = [{
    case.type = "ir"
    case.code = "doublesanta"
    case.date = "20241225"
    network.addr = "10.10.10.0"
    network.cidr = "24"
    software_tag.plaso       = "20241006"
    software_tag.timesketch  = "20241129"
    software_tag.ts_notebook = "sha256:4ca1d875c49b3e8ba2fa55d3776bcbd586b9dcf8a3537db4dcc6c07e8f5c3844"
    volume_size.bastion_root     = 4000000000
    volume_size.gateway_root     = 2000000000
    volume_size.worker_root      = 20000000000
    volume_size.worker_data      = 100000000000
    volume_size.iris_root        = 10000000000
    volume_size.siftstation_root = 10000000000
  },
  {
    case.type = "df"
    case.code = "submarine"
    case.date = "20250317"
    network.addr = "10.10.20.0"
    network.cidr = "24"
    software_tag.plaso       = "20241006"
    software_tag.timesketch  = "20241129"
    software_tag.ts_notebook = "sha256:4ca1d875c49b3e8ba2fa55d3776bcbd586b9dcf8a3537db4dcc6c07e8f5c3844"
    volume_size.bastion_root     = 4000000000
    volume_size.gateway_root     = 2000000000
    volume_size.worker_root      = 20000000000
    volume_size.worker_data      = 100000000000
    volume_size.iris_root        = 10000000000
    volume_size.siftstation_root = 10000000000
  }]
  */
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
    type = string
    path = string
  })
}
#
# DFIR Pool
variable "dfir_pool_config" {
  description = "Storage pool name and path for DFIR nodes"
  type = object({
    name      = string
    base_path = string
  })
  default = {
    name      = "dfir_images"
    base_path = "/var/lib/libvirt/images/dfir"
  }
}
#
#
# Base Images
#
# Alpine
variable "bi_alpine" {
  description = "Image source for Alpine Linux"
  type = object({
    name    = string
    release = string
    format  = string
    source  = string
  })
  default = {
    name    = "alpine-3.22.1-x86_64.qcow2"
    release = "v3.22"
    format  = "qcow2"
    source  = "http://dl-cdn.alpinelinux.org/alpine/v3.22/releases/cloud/generic_alpine-3.22.1-x86_64-bios-cloudinit-r0.qcow2"
  }
}
#
# Debian
variable "bi_debian" {
  description = "Image source for Debian Linux"
  type = object({
    name    = string
    release = string
    format  = string
    source  = string
  })
  default = {
    name    = "debian-13-generic-amd64.qcow2"
    release = "trixie"
    format  = "qcow2"
    source  = "http://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
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
