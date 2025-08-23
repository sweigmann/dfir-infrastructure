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
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">=2.3.7"
    }
    time = {
      source  = "hashicorp/time"
      version = ">=0.13.1"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.7.2"
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
  case_id                 = "${var.case_config.type}-${var.case_config.code}-${var.case_config.date}"
  case_network_domain     = "${local.case_id}.${var.access_network.domain}"
  case_network_netmask    = cidrnetmask("${var.case_network.network_addr}/${var.case_network.network_cidr}")
  case_network_localdns   = cidrhost("${var.case_network.network_addr}/${var.case_network.network_cidr}", 1)
  case_network_gateway    = cidrhost("${var.case_network.network_addr}/${var.case_network.network_cidr}", 2)
  access_network_gateway  = libvirt_domain.gateway.network_interface.0.addresses.0
  case_network_dhcp_first = cidrhost("${var.case_network.network_addr}/${var.case_network.network_cidr}", 3)
  case_network_dhcp_last  = cidrhost("${var.case_network.network_addr}/${var.case_network.network_cidr}", 6)
  # FQDN for bastion differs as it lives within the access network
  fqdn_bastion = "bastion-${local.case_id}.${var.access_network.domain}"
  # FQDNs for all other hosts which live within the case network
  fqdn_gateway     = "gateway.${local.case_network_domain}"
  fqdn_worker      = "worker.${local.case_network_domain}"
  fqdn_siftstation = "siftstation.${local.case_network_domain}"
  # Timesketch config
  timesketch_admuser = "tsadm"
  timesketch_admpass = random_string.random_tsadm_pass.result
  timesketch_user    = "dfir"
  timesketch_pass    = random_string.random_tsusr_pass.result
  # Users
  users_case_vms = jsondecode(file("${path.module}/users-case-vms.json"))
  users_gateway  = jsondecode(file("${path.module}/users-gateway.json"))

}
#
#
# Random Strings for later use
#
# These resources will only be rebuild when the Terraform/Tofu
# state file is reset or deleted.
# We cannot set the keepers to the worker node itself or the
# cloud-init disks as this would introduce deduction circles.
# The Case ID is used instead, making the randomized values
# independent from any case infrastructure.
resource "random_string" "random_tsadm_pass" {
  keepers = {
    #first = "${timestamp()}"
    first = local.case_id
  }
  length  = 20
  special = false
  upper   = true
}
resource "random_string" "random_tsusr_pass" {
  keepers = {
    #  first = "${timestamp()}"
    first = local.case_id
  }
  length  = 20
  special = false
  upper   = true
}
#
#
# Pools
#
# Base Image Pool
resource "libvirt_pool" "base_pool" {
  name = "base"
  type = "dir"
  target {
    path = var.base_pool_config.path
  }
}
#
# Bastion Pool (not needed?)
#resource "libvirt_pool" "bastion_pool" {
#  name = "bastion_hosts"
#  type = "dir"
#  target {
#    path = var.bastion_pool_config.base_path
#  }
#}
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
resource "libvirt_volume" "debian" {
  name   = "debian-${var.base_image_debian.release}-generic-amd64.${var.base_image_debian.format}"
  format = var.base_image_debian.format
  source = var.base_image_debian.source
  pool   = libvirt_pool.base_pool.name
}
resource "libvirt_volume" "alpine" {
  name   = "alpine-${var.base_image_alpine.release}-x86_64.${var.base_image_alpine.format}"
  format = var.base_image_alpine.format
  source = var.base_image_alpine.source
  pool   = libvirt_pool.base_pool.name
}
#
#
# Networks
#
# Access Network (Bastion Hosts)
resource "libvirt_network" "access_network" {
  name      = "access-net"
  mode      = "route"
  domain    = var.access_network.domain
  autostart = true
  addresses = var.access_network.addresses
  dhcp {
    enabled = true
  }
  dns {
    enabled    = true
    local_only = true
    forwarders {
      address = var.access_network.external_dns
    }
    forwarders {
      domain  = local.case_network_domain
      address = local.case_network_localdns
    }
  }
  dnsmasq_options {
    options {
      option_name  = "listen-address"
      option_value = var.access_network.external_addr
    }
  }
}
#
# Case Network
resource "libvirt_network" "case_network" {
  name      = local.case_id
  mode      = "none"
  domain    = local.case_network_domain
  autostart = true
  addresses = ["${var.case_network.network_addr}/${var.case_network.network_cidr}"]
  dhcp {
    enabled = true
  }
  dns {
    enabled    = true
    local_only = true
    forwarders {
      address = local.case_network_gateway
    }
    hosts {
      hostname = local.fqdn_gateway
      ip       = local.case_network_gateway
    }
  }
  dnsmasq_options {
    options {
      option_name  = "dhcp-option"
      option_value = "option:router,${local.case_network_gateway}"
    }
    options {
      option_name  = "dhcp-range"
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
  depends_on      = [libvirt_domain.gateway]
  create_duration = "60s"
}
resource "time_sleep" "wait_for_worker" {
  depends_on      = [libvirt_domain.worker]
  create_duration = "360s"
}
#
# gateway init
data "cloudinit_config" "user_data_gateway" {
  # https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config
  gzip          = false
  base64_encode = false
  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/cloudinit/gateway.tftpl",
      {
        hostname        = "gateway"
        fqdn            = local.fqdn_gateway
        distro_release  = var.base_image_alpine.release
        nameserver      = var.access_network.external_dns
        internal_domain = local.case_network_domain
        internal_dns    = local.case_network_localdns
        internal_net    = var.case_network.network_addr
        internal_addr   = local.case_network_gateway
        internal_cidr   = var.case_network.network_cidr
        users           = local.users_gateway
      }
    )
  }
}
resource "libvirt_cloudinit_disk" "cloudinit_gateway" {
  name      = "cloudinit_gateway.iso"
  user_data = data.cloudinit_config.user_data_gateway.rendered
  pool      = libvirt_pool.case_pool.name
}
# gateway root volume
resource "libvirt_volume" "gateway_root" {
  name             = "gateway-root.qcow2"
  format           = "qcow2"
  size             = var.volume_size.gateway_root
  pool             = libvirt_pool.case_pool.name
  base_volume_id   = libvirt_volume.alpine.id
  base_volume_pool = libvirt_pool.base_pool.name
}
# gateway domain
resource "libvirt_domain" "gateway" {
  name      = "${local.case_id}-gateway"
  autostart = true
  memory    = "256"
  vcpu      = 2
  cloudinit = libvirt_cloudinit_disk.cloudinit_gateway.id
  cpu {
    mode = "host-passthrough"
  }
  disk {
    volume_id = libvirt_volume.gateway_root.id
    scsi      = true
  }
  network_interface {
    network_id = libvirt_network.access_network.id
    # Do not expose the gateway to the outside via DNS
    #hostname = "gateway-${local.case_id}.${var.access_network.domain}"
    wait_for_lease = true
  }
  network_interface {
    network_id     = libvirt_network.case_network.id
    hostname       = local.fqdn_gateway
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
  gzip          = false
  base64_encode = false
  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/cloudinit/bastion.tftpl",
      {
        hostname       = "bastion"
        fqdn           = local.fqdn_bastion
        distro_release = var.base_image_debian.release
        gateway_addr   = local.access_network_gateway
        internal_net   = var.case_network.network_addr
        internal_cidr  = var.case_network.network_cidr
        users          = local.users_case_vms
      }
    )
  }
}
resource "libvirt_cloudinit_disk" "cloudinit_bastion" {
  name      = "cloudinit_bastion.iso"
  user_data = data.cloudinit_config.user_data_bastion.rendered
  pool      = libvirt_pool.case_pool.name
}
# bastion root volume
resource "libvirt_volume" "bastion_root" {
  name             = "bastion-root.qcow2"
  format           = "qcow2"
  size             = var.volume_size.bastion_root
  pool             = libvirt_pool.case_pool.name
  base_volume_id   = libvirt_volume.debian.id
  base_volume_pool = libvirt_pool.base_pool.name
}
# bastion domain
resource "libvirt_domain" "bastion" {
  name      = "${local.case_id}-bastion"
  autostart = true
  memory    = "1024"
  vcpu      = 1
  cloudinit = libvirt_cloudinit_disk.cloudinit_bastion.id
  cpu {
    mode = "host-passthrough"
  }
  disk {
    volume_id = libvirt_volume.bastion_root.id
    scsi      = true
  }
  network_interface {
    network_id     = libvirt_network.access_network.id
    hostname       = local.fqdn_bastion
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
# worker init
data "cloudinit_config" "user_data_worker" {
  # https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config
  gzip          = false
  base64_encode = false
  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/cloudinit/worker.tftpl",
      {
        hostname       = "worker"
        fqdn           = local.fqdn_worker
        distro_release = var.base_image_debian.release
        internal_net   = var.case_network.network_addr
        internal_cidr  = var.case_network.network_cidr
        users          = local.users_case_vms
        case_id        = local.case_id
        ts_admuser     = local.timesketch_admuser
        ts_admpass     = local.timesketch_admpass
        ts_user        = local.timesketch_user
        ts_pass        = local.timesketch_pass
        ts_version     = var.software_tag.timesketch
        ts_nb_version  = var.software_tag.ts_notebook
        plaso_version  = var.software_tag.plaso
      }
    )
  }
  part {
    filename = "timesketch_template.ipynb"
    content = templatefile(
      "${path.module}/jupyter/ts_nb_template.tftpl",
      {
        fqdn    = local.fqdn_worker
        case_id = local.case_id
        ts_user = local.timesketch_user
        ts_pass = local.timesketch_pass
      }
    )
  }
}
resource "libvirt_cloudinit_disk" "cloudinit_worker" {
  name      = "cloudinit_worker.iso"
  user_data = data.cloudinit_config.user_data_worker.rendered
  pool      = libvirt_pool.case_pool.name
}
# worker root volume
resource "libvirt_volume" "worker_root" {
  name             = "worker-root.qcow2"
  format           = "qcow2"
  size             = var.volume_size.worker_root
  pool             = libvirt_pool.case_pool.name
  base_volume_id   = libvirt_volume.debian.id
  base_volume_pool = libvirt_pool.base_pool.name
}
# worker data volume
resource "libvirt_volume" "worker_data" {
  name   = "worker-data.qcow2"
  format = "qcow2"
  size   = var.volume_size.worker_data
  pool   = libvirt_pool.case_pool.name
}
# worker domain
resource "libvirt_domain" "worker" {
  name = "${local.case_id}-worker"
  depends_on = [
    libvirt_domain.gateway,
    time_sleep.wait_for_gateway
  ]
  autostart = true
  #memory = "16384"
  memory    = "24576"
  vcpu      = 6
  cloudinit = libvirt_cloudinit_disk.cloudinit_worker.id
  cpu {
    mode = "host-passthrough"
  }
  disk {
    volume_id = libvirt_volume.worker_root.id
    scsi      = true
    wwn       = "b0bafe77600db007"
  }
  disk {
    volume_id = libvirt_volume.worker_data.id
    scsi      = true
    # define an arbitrary WSN to enable identification in the guest os
    # results:
    #   /dev/disk/by-id/wwn-0xb0bafe77600dda7a
    #   /dev/disk/by-id/scsi-3b0bafe77600dda7a
    wwn = "b0bafe77600dda7a"
  }
  network_interface {
    network_id     = libvirt_network.case_network.id
    hostname       = local.fqdn_worker
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
# siftstation init
data "cloudinit_config" "user_data_siftstation" {
  # https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config
  gzip          = false
  base64_encode = false
  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/cloudinit/siftstation.tftpl",
      {
        hostname       = "siftstation"
        fqdn           = local.fqdn_siftstation
        distro_release = var.base_image_debian.release
        internal_net   = var.case_network.network_addr
        internal_cidr  = var.case_network.network_cidr
        worker_addr    = libvirt_domain.worker.network_interface.0.addresses.0
        users          = local.users_case_vms
      }
    )
  }
}
resource "libvirt_cloudinit_disk" "cloudinit_siftstation" {
  name      = "cloudinit_siftstation.iso"
  user_data = data.cloudinit_config.user_data_siftstation.rendered
  pool      = libvirt_pool.case_pool.name
}
# siftstation root volume
resource "libvirt_volume" "siftstation_root" {
  name             = "siftstation-root.qcow2"
  format           = "qcow2"
  size             = var.volume_size.siftstation_root
  pool             = libvirt_pool.case_pool.name
  base_volume_id   = libvirt_volume.debian.id
  base_volume_pool = libvirt_pool.base_pool.name
}
# siftstation domain
resource "libvirt_domain" "siftstation" {
  name = "${local.case_id}-siftstation"
  depends_on = [
    libvirt_domain.worker,
    time_sleep.wait_for_worker
  ]
  autostart = true
  memory    = "8192"
  vcpu      = 4
  cloudinit = libvirt_cloudinit_disk.cloudinit_siftstation.id
  cpu {
    mode = "host-passthrough"
  }
  disk {
    volume_id = libvirt_volume.siftstation_root.id
    scsi      = true
  }
  network_interface {
    network_id     = libvirt_network.case_network.id
    hostname       = local.fqdn_siftstation
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
#
# Prepare some information to pass to the users
#
# How to connect to the boxes via SSH...
output "ssh_config_bastion" {
  value = "ssh -D <proxyport> -N -f -l <user> ${local.fqdn_bastion}"
}
output "ssh_config_siftstation" {
  value = "ssh -i <sshkey> -l <user> -o ProxyCommand='nc -x 127.0.0.1:<proxyport> %h %p' ${local.fqdn_siftstation}"
}
output "ssh_config_worker" {
  value = "ssh -i <sshkey> -l <user> -o ProxyCommand='nc -x 127.0.0.1:<proxyport> %h %p' ${local.fqdn_worker}"
}
# How to log onto Timesketch
output "timesketch_url" {
  value = "Timesketch URL (via SSH SOCKS): http://${local.fqdn_worker}"
}
output "timesketch_notebook_url" {
  value = "Notebook URL (via SSH SOCKS): http://${local.fqdn_worker}:8844/?token=timesketch"
}
output "timesketch_admin_user" {
  value = "Timesketch privileged user/pass: ${local.timesketch_admuser}/${local.timesketch_admpass}"
}
output "timesketch_user" {
  value = "Timesketch non-priv user/pass: ${local.timesketch_user}/${local.timesketch_pass}"
}
