# Terraform Main
# vim: set expandtab ts=2 sw=2 ft=terraform:
#
# Provider Configuration
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">=0.8.3"
    }
  }
}
provider "libvirt" {
  uri = var.libvirt_config.uri
}
#
#
# Local Variables
locals {
  case_id = "${var.case_config.type}-${var.case_config.code}-${var.case_config.date}"
  case_network_domain = "${local.case_id}.${var.access_network.domain}"
  case_network_netmask = cidrnetmask("${var.case_network.network_addr}/${var.case_network.network_cidr}")
  case_network_localdns = cidrhost("${var.case_network.network_addr}/${var.case_network.network_cidr}", 1)
  case_network_gateway = cidrhost("${var.case_network.network_addr}/${var.case_network.network_cidr}", 2)
  access_network_gateway = libvirt_domain.gateway.network_interface.0.addresses.0
  case_network_dhcp_first = cidrhost("${var.case_network.network_addr}/${var.case_network.network_cidr}", 3)
  case_network_dhcp_last = cidrhost("${var.case_network.network_addr}/${var.case_network.network_cidr}", 6)
  # FQDN for bastion differs to put DNS record into the access network
  fqdn_bastion = "bastion-${local.case_network_domain}"
  # FQDNs for all other hosts are made to be put into the case network
  fqdn_gateway = "gateway.${local.case_network_domain}"
  fqdn_podman = "podman.${local.case_network_domain}"
}
#
#
# Pools
#
# Base Image Pool
resource "libvirt_pool" "base_pool" {
  name = "base_images"
  type = "dir"
  target {
    path = var.base_pool_config.path
  }
}
#
# DFIR Pool
resource "libvirt_pool" "case_pool" {
  name = local.case_id
  type = "dir"
  target {
    path = format("%s/%s", var.dfir_pool_config.base_path, "${local.case_id}")
  }
}
#
# Configure QCOW2 image sources
resource "libvirt_volume" "debian_12" {
  name = "debian-12-generic-amd64.qcow2"
  format = "qcow2"
  source = "http://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
  pool = libvirt_pool.base_pool.name
}
resource "libvirt_volume" "alpine" {
  name = "alpine-3.21.2-x86_64.qcow2"
  format = "qcow2"
  source = "http://dl-cdn.alpinelinux.org/alpine/v3.21/releases/cloud/generic_alpine-3.21.2-x86_64-bios-cloudinit-r0.qcow2"
  pool = libvirt_pool.base_pool.name
}
#
#
# Networks
#
# Access Network (Jump Hosts)
resource "libvirt_network" "access_network" {
  name = "access-net"
  mode = "route"
  domain = var.access_network.domain
  autostart = true
  addresses = var.access_network.addresses
  dhcp {
    enabled = true
  }
  dns {
    enabled = true
    local_only = true
    forwarders {
      address = var.access_network.external_dns
    }
    forwarders {
      domain = local.case_network_domain
      address = local.case_network_localdns
    }
  }
  dnsmasq_options {
    options {
      option_name   = "listen-address"
      option_value  = var.access_network.external_addr
    }
  }
}
#
# Case Network
resource "libvirt_network" "case_network" {
  name = local.case_id
  mode = "none"
  domain = local.case_network_domain
  autostart = true
  addresses = [ "${var.case_network.network_addr}/${var.case_network.network_cidr}" ]
  dhcp {
    enabled = true
  }
  dns {
    enabled = true
    local_only = true
    forwarders {
      address = local.case_network_gateway
    }
    hosts {
      hostname = local.fqdn_gateway
      ip = local.case_network_gateway
    }
  }
  dnsmasq_options {
    options {
      option_name   = "dhcp-option"
      option_value  = "option:router,${local.case_network_gateway}"
    }
    options {
      option_name = "dhcp-range"
      option_value = "${local.case_network_dhcp_first},${local.case_network_dhcp_last},${local.case_network_netmask}"
    }
  }
}
#
#
# Nodes
#
# Timers to give nodes time to finish internal setup
resource "time_sleep" "wait_for_gateway" {
  depends_on =  [ libvirt_domain.gateway ]
  create_duration = "60s"
}
# gateway init
data "cloudinit_config" "user_data_gateway" {
  # https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config
  gzip            = false
  base64_encode   = false
  part {
    filename      = "cloud-config.yaml"
    content_type  = "text/cloud-config"
    content       = templatefile(
      "${path.module}/cloudinit/gateway.tftpl",
      {
        hostname        = "gateway-${local.case_id}"
        fqdn            = local.fqdn_gateway
        distro_release  = "v3.21"
        #distro_release  = "latest-stable"
        nameserver      = var.access_network.external_dns
        internal_domain = local.case_network_domain
        internal_dns    = local.case_network_localdns
        internal_net    = var.case_network.network_addr
        internal_addr   = local.case_network_gateway
        internal_cidr   = var.case_network.network_cidr
        username        = var.user_config.username
        usergecos       = var.user_config.usergecos
        password        = var.user_config.password
        ssh_key         = var.user_config.ssh_key
      }
    )
  }
}
resource "libvirt_cloudinit_disk" "cloudinit_gateway" {
  name            = "cloudinit_gateway.iso"
  user_data       = data.cloudinit_config.user_data_gateway.rendered
  #network_config  = data.template_file.network_config.rendered
  pool            = libvirt_pool.case_pool.name
}
# gateway root volume -- 2G
resource "libvirt_volume" "gateway_root" {
  name = "gateway-root.qcow2"
  format = "qcow2"
  size = 2000000000
  pool = libvirt_pool.case_pool.name
  base_volume_id = libvirt_volume.alpine.id
  base_volume_pool = libvirt_pool.base_pool.name
}
# gateway domain
resource "libvirt_domain" "gateway" {
  name = "${local.case_id}-gateway"
  autostart = true
  memory = "256"
  vcpu = 2
  cloudinit = libvirt_cloudinit_disk.cloudinit_gateway.id
  cpu {
    mode = "host-passthrough"
  }
  disk {
    volume_id = libvirt_volume.gateway_root.id
    scsi = true
  }
  network_interface {
    network_id = libvirt_network.access_network.id
    # Do not expose the gateway to the outside via DNS
    #hostname = "gateway-${local.case_id}.${var.access_network.domain}"
    wait_for_lease = true
  }
  network_interface {
    network_id = libvirt_network.case_network.id
    hostname = local.fqdn_gateway
    wait_for_lease = false
  }
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }
}
#
# bastion init
data "cloudinit_config" "user_data_bastion" {
  # https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config
  gzip            = false
  base64_encode   = false
  part {
    filename      = "cloud-config.yaml"
    content_type  = "text/cloud-config"
    content       = templatefile(
      "${path.module}/cloudinit/bastion.tftpl",
      {
        hostname        = "bastion"
        fqdn            = local.fqdn_bastion
        distro_release  = "bookworm"
        gateway_addr    = local.access_network_gateway
        internal_net    = var.case_network.network_addr
        internal_cidr   = var.case_network.network_cidr
        username        = var.user_config.username
        usergecos       = var.user_config.usergecos
        password        = var.user_config.password
        ssh_key         = var.user_config.ssh_key
      }
    )
  }
}
#data "couldinit_config" "meta_data_bastion" {
#  gzip            = false
#  base64_encode   = false
#  part {
#    filename      = "meta-data.yaml"
#  }
#}
resource "libvirt_cloudinit_disk" "cloudinit_bastion" {
  name            = "cloudinit_bastion.iso"
  user_data       = data.cloudinit_config.user_data_bastion.rendered
  #network_config  = data.template_file.network_config.rendered
  pool            = libvirt_pool.case_pool.name
}
# bastion root volume -- 4G
resource "libvirt_volume" "bastion_root" {
  name = "bastion-root.qcow2"
  format = "qcow2"
  size = 4000000000
  pool = libvirt_pool.case_pool.name
  base_volume_id = libvirt_volume.debian_12.id
  base_volume_pool = libvirt_pool.base_pool.name
}
# bastion domain
resource "libvirt_domain" "bastion" {
  name = "${local.case_id}-bastion"
  autostart = true
  memory = "1024"
  vcpu = 1
  cloudinit = libvirt_cloudinit_disk.cloudinit_bastion.id
  cpu {
    mode = "host-passthrough"
  }
  disk {
    volume_id = libvirt_volume.bastion_root.id
    scsi = true
  }
  network_interface {
    network_id = libvirt_network.access_network.id
    hostname = local.fqdn_bastion
    wait_for_lease = true
  }
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }
  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
#
# podman init
data "cloudinit_config" "user_data_podman" {
  # https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config
  gzip            = false
  base64_encode   = false
  part {
    filename      = "cloud-config.yaml"
    content_type  = "text/cloud-config"
    content       = templatefile(
      "${path.module}/cloudinit/podman.tftpl",
      {
        hostname        = "podman"
        fqdn            = local.fqdn_podman
        distro_release  = "bookworm"
        username        = var.user_config.username
        usergecos       = var.user_config.usergecos
        password        = var.user_config.password
        ssh_key         = var.user_config.ssh_key
      }
    )
  }
}
#data "couldinit_config" "meta_data_podman" {
#  gzip            = false
#  base64_encode   = false
#  part {
#    filename      = "meta-data.yaml"
#  }
#}
resource "libvirt_cloudinit_disk" "cloudinit_podman" {
  name            = "cloudinit_podman.iso"
  user_data       = data.cloudinit_config.user_data_podman.rendered
  #network_config  = data.template_file.network_config.rendered
  pool            = libvirt_pool.case_pool.name
}
# podman root volume -- 10G
resource "libvirt_volume" "podman_root" {
  name = "podman-root.qcow2"
  format = "qcow2"
  size = 10000000000
  pool = libvirt_pool.case_pool.name
  base_volume_id = libvirt_volume.debian_12.id
  base_volume_pool = libvirt_pool.base_pool.name
}
# podman data volume -- 100G
resource "libvirt_volume" "podman_data" {
  name = "podman-data.qcow2"
  format = "qcow2"
  size = 100000000000
  pool = libvirt_pool.case_pool.name
}
# podman domain
resource "libvirt_domain" "podman" {
  name = "${local.case_id}-podman"
  depends_on = [
    libvirt_domain.gateway,
    time_sleep.wait_for_gateway
  ]
  autostart = true
  memory = "8192"
  vcpu = 4
  cloudinit = libvirt_cloudinit_disk.cloudinit_podman.id
  cpu {
    mode = "host-passthrough"
  }
  disk {
    volume_id = libvirt_volume.podman_root.id
    scsi = true
    wwn = "b0bafe77600db007"
  }
  disk {
    volume_id = libvirt_volume.podman_data.id
    scsi = true
    # define an arbitrary WSN to enable identification in the guest os
    # results:
    #   /dev/disk/by-id/wwn-0xb0bafe77600dda7a
    #   /dev/disk/by-id/scsi-3b0bafe77600dda7a
    wwn = "b0bafe77600dda7a"
  }
  network_interface {
    network_id = libvirt_network.case_network.id
    hostname = local.fqdn_podman
    wait_for_lease = true
  }
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }
  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
