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
#
#
# Networks
resource "libvirt_network" "dfir_network" {
  name = local.case_id
  mode = "route"
  domain = var.case_network.domain
  autostart = true
  addresses = var.case_network.addresses
  dns {
    enabled = true
    local_only = true
    forwarders {
      address = "192.168.30.254"
    }
    #hosts {
    #  hostname = "${var.case_config.type}_${var.case_config.code}_${var.case_config.date}_node1"
    #  ip = "192.168.31.2"
    #}
  }
  dnsmasq_options {
    options {
      option_name   = "listen-address"
      option_value  = var.case_network.external_addr
    }
  }
}
#
#
# Nodes
#
# node1 init
data "cloudinit_config" "user_data_node1" {
  # https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config
  gzip            = false
  base64_encode   = false
  part {
    filename      = "cloud-config.yaml"
    content_type  = "text/cloud-config"
    #content       = file("${path.module}/cloudinit/node1.yaml")
    content       = templatefile(
      "${path.module}/cloudinit/node1.tftpl",
      {
        hostname        = "${local.case_id}-node1"
        fqdn            = "${local.case_id}-node1.${var.case_network.domain}"
        distro_release  = "bookworm"
        username        = var.user_config.username
        usergecos       = var.user_config.usergecos
        password        = var.user_config.password
        ssh_key         = var.user_config.ssh_key
      }
    )
  }
}
#data "couldinit_config" "meta_data_node1" {
#  gzip            = false
#  base64_encode   = false
#  part {
#    filename      = "meta-data.yaml"
#  }
#}
resource "libvirt_cloudinit_disk" "cloudinit_node1" {
  name            = "cloudinit_node1.iso"
  user_data       = data.cloudinit_config.user_data_node1.rendered
  #network_config  = data.template_file.network_config.rendered
  pool            = libvirt_pool.case_pool.name
}
# node1 volume -- 10G
resource "libvirt_volume" "node1" {
  name = "${local.case_id}-node1.qcow2"
  format = "qcow2"
  size = 10000000000
  pool = libvirt_pool.case_pool.name
  base_volume_id = libvirt_volume.debian_12.id
  base_volume_pool = libvirt_pool.base_pool.name
}
# node1 domain
resource "libvirt_domain" "node1" {
  name = "${local.case_id}-node1"
  autostart = true
  memory = "2048"
  vcpu = 2
  cloudinit = libvirt_cloudinit_disk.cloudinit_node1.id
  cpu {
    mode = "host-passthrough"
  }
  disk {
    volume_id = libvirt_volume.node1.id
    scsi = true
  }
  network_interface {
    network_id = libvirt_network.dfir_network.id
    hostname = "${local.case_id}-node1"
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
