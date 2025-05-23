# Terraform Variable declarations
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
# Bastion Pool
variable "bastion_pool_config" {
  description = "Storage pool name and path for bastion nodes"
  type = object({
    name      = string
    base_path = string
  })
  default = {
    name      = "bastion_images"
    base_path = "/var/lib/libvirt/images/bastion"
  }
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
variable "base_image_alpine" {
  description = "Image source for Alpine Linux"
  type = object({
    name    = string
    release = string
    format  = string
    source  = string
  })
  default = {
    name    = "alpine-3.21.2-x86_64.qcow2"
    release = "v3.21"
    format  = "qcow2"
    source  = "http://dl-cdn.alpinelinux.org/alpine/v3.21/releases/cloud/generic_alpine-3.21.2-x86_64-bios-cloudinit-r0.qcow2"
  }
}
#
# Debian
variable "base_image_debian" {
  description = "Image source for Debian Linux"
  type = object({
    name    = string
    release = string
    format  = string
    source  = string
  })
  default = {
    name    = "debian-12-generic-amd64.qcow2"
    release = "bookworm"
    format  = "qcow2"
    source  = "http://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
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
variable "software_tag" {
  description = "Tags and versions for software to be installed"
  type = object({
    plaso       = string
    timesketch  = string
    ts_notebook = string
  })
  default = {
    plaso       = "20241006"
    timesketch  = "20241129"
    ts_notebook = "sha256:4ca1d875c49b3e8ba2fa55d3776bcbd586b9dcf8a3537db4dcc6c07e8f5c3844"
  }
}
#
#
# Volume sizes
variable "volume_size" {
  description = "Size for some volumes (in Bytes)"
  type = object({
    bastion_root     = number
    gateway_root     = number
    worker_root      = number
    worker_data      = number
    siftstation_root = number
  })
  default = {
    bastion_root     = 4000000000
    gateway_root     = 2000000000
    worker_root      = 20000000000
    worker_data      = 100000000000
    siftstation_root = 10000000000
  }
}
