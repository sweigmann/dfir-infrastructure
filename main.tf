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
# Random Strings for later use
resource "random_string" "random_tsadm_pass" {
  keepers = {
    first = "${timestamp()}"
  }
  length  = 10
  special = false
  upper   = true
}
resource "random_string" "random_tsusr_pass" {
  keepers = {
    first = "${timestamp()}"
  }
  length  = 10
  special = false
  upper   = true
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
  # FQDN for bastion differs as it lives within the access network
  fqdn_bastion = "bastion.${var.access_network.domain}"
  # FQDNs for all other hosts which live within the case network
  fqdn_gateway = "gateway.${local.case_network_domain}"
  fqdn_worker = "worker.${local.case_network_domain}"
  fqdn_siftstation = "siftstation.${local.case_network_domain}"
  # Timesketch config
  timesketch_admuser = "tsadm"
  timesketch_admpass = random_string.random_tsadm_pass.result
  timesketch_user = var.user_config.username
  timesketch_pass = random_string.random_tsusr_pass.result
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
resource "time_sleep" "wait_for_worker" {
  depends_on =  [ libvirt_domain.worker ]
  create_duration = "360s"
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
  name = "bastion"
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
# worker init
data "cloudinit_config" "user_data_worker" {
  # https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config
  gzip            = false
  base64_encode   = false
  part {
    filename      = "cloud-config.yaml"
    content_type  = "text/cloud-config"
    content       = templatefile(
      "${path.module}/cloudinit/worker.tftpl",
      {
        hostname        = "worker"
        fqdn            = local.fqdn_worker
        distro_release  = "bookworm"
        internal_net    = var.case_network.network_addr
        internal_cidr   = var.case_network.network_cidr
        username        = var.user_config.username
        usergecos       = var.user_config.usergecos
        password        = var.user_config.password
        ssh_key         = var.user_config.ssh_key
        ts_admuser      = local.timesketch_admuser
        ts_admpass      = local.timesketch_admpass
        ts_user         = local.timesketch_user
        ts_pass         = local.timesketch_pass
      }
    )
  }
}
#data "couldinit_config" "meta_data_worker" {
#  gzip            = false
#  base64_encode   = false
#  part {
#    filename      = "meta-data.yaml"
#  }
#}
resource "libvirt_cloudinit_disk" "cloudinit_worker" {
  name            = "cloudinit_worker.iso"
  user_data       = data.cloudinit_config.user_data_worker.rendered
  #network_config  = data.template_file.network_config.rendered
  pool            = libvirt_pool.case_pool.name
}
# worker root volume -- 20G
resource "libvirt_volume" "worker_root" {
  name = "worker-root.qcow2"
  format = "qcow2"
  size = 20000000000
  pool = libvirt_pool.case_pool.name
  base_volume_id = libvirt_volume.debian_12.id
  base_volume_pool = libvirt_pool.base_pool.name
}
# worker data volume -- 100G
resource "libvirt_volume" "worker_data" {
  name = "worker-data.qcow2"
  format = "qcow2"
  size = 100000000000
  pool = libvirt_pool.case_pool.name
}
# worker domain
resource "libvirt_domain" "worker" {
  name = "${local.case_id}-worker"
  depends_on = [
    libvirt_domain.gateway,
    time_sleep.wait_for_gateway
  ]
  autostart = true
  memory = "16384"
  vcpu = 6
  cloudinit = libvirt_cloudinit_disk.cloudinit_worker.id
  cpu {
    mode = "host-passthrough"
  }
  disk {
    volume_id = libvirt_volume.worker_root.id
    scsi = true
    wwn = "b0bafe77600db007"
  }
  disk {
    volume_id = libvirt_volume.worker_data.id
    scsi = true
    # define an arbitrary WSN to enable identification in the guest os
    # results:
    #   /dev/disk/by-id/wwn-0xb0bafe77600dda7a
    #   /dev/disk/by-id/scsi-3b0bafe77600dda7a
    wwn = "b0bafe77600dda7a"
  }
  network_interface {
    network_id = libvirt_network.case_network.id
    hostname = local.fqdn_worker
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
  gzip            = false
  base64_encode   = false
  part {
    filename      = "cloud-config.yaml"
    content_type  = "text/cloud-config"
    content       = templatefile(
      "${path.module}/cloudinit/siftstation.tftpl",
      {
        hostname        = "siftstation"
        fqdn            = local.fqdn_siftstation
        distro_release  = "bookworm"
        internal_net    = var.case_network.network_addr
        internal_cidr   = var.case_network.network_cidr
        worker_addr     = libvirt_domain.worker.network_interface.0.addresses.0
        username        = var.user_config.username
        usergecos       = var.user_config.usergecos
        password        = var.user_config.password
        ssh_key         = var.user_config.ssh_key
      }
    )
  }
}
#data "couldinit_config" "meta_data_siftstation" {
#  gzip            = false
#  base64_encode   = false
#  part {
#    filename      = "meta-data.yaml"
#  }
#}
resource "libvirt_cloudinit_disk" "cloudinit_siftstation" {
  name            = "cloudinit_siftstation.iso"
  user_data       = data.cloudinit_config.user_data_siftstation.rendered
  #network_config  = data.template_file.network_config.rendered
  pool            = libvirt_pool.case_pool.name
}
# siftstation root volume -- 10G
resource "libvirt_volume" "siftstation_root" {
  name = "siftstation-root.qcow2"
  format = "qcow2"
  size = 10000000000
  pool = libvirt_pool.case_pool.name
  base_volume_id = libvirt_volume.debian_12.id
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
  memory = "8192"
  vcpu = 4
  cloudinit = libvirt_cloudinit_disk.cloudinit_siftstation.id
  cpu {
    mode = "host-passthrough"
  }
  disk {
    volume_id = libvirt_volume.siftstation_root.id
    scsi = true
  }
  network_interface {
    network_id = libvirt_network.case_network.id
    hostname = local.fqdn_siftstation
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
