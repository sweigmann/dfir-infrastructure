# Terraform Module: cases
# vim: set expandtab ts=2 sw=2 ft=terraform:
#
#
#
# Local Variables
#
locals {
  case_nwk_domain     = "${var.case_id}.${var.access_nwk_domain}"
  case_nwk_netmask    = cidrnetmask("${var.nwk_addr}/${var.nwk_cidr}")
  case_nwk_localdns   = cidrhost("${var.nwk_addr}/${var.nwk_cidr}", 1)
  case_nwk_gateway    = cidrhost("${var.nwk_addr}/${var.nwk_cidr}", 2)
  access_nwk_gateway  = libvirt_domain.gateway.network_interface.0.addresses.0
  case_nwk_dhcp_first = cidrhost("${var.nwk_addr}/${var.nwk_cidr}", 3)
  case_nwk_dhcp_last  = cidrhost("${var.nwk_addr}/${var.nwk_cidr}", 6)
  # FQDN for bastion differs as it lives within the access network
  fqdn_bastion = "bastion-${var.case_id}.${var.access_nwk_domain}"
  # FQDNs for all other hosts which live within the case network
  fqdn_gateway     = "gateway.${local.case_nwk_domain}"
  fqdn_worker      = "worker.${local.case_nwk_domain}"
  fqdn_siftstation = "siftstation.${local.case_nwk_domain}"
  # Timesketch config
  timesketch_admuser = "tsadm"
  timesketch_admpass = random_string.random_tsadm_pass.result
  timesketch_user    = "dfir"
  timesketch_pass    = random_string.random_tsusr_pass.result
  # Jupyter config
  jupyter_port = "8888"
  # Users
  users_case_vms = jsondecode(file(var.users_case_vms))
  users_gateway  = jsondecode(file(var.users_gateway))
}
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
    first = var.case_id
  }
  length  = 20
  special = false
  upper   = true
}
resource "random_string" "random_tsusr_pass" {
  keepers = {
    #  first = "${timestamp()}"
    first = var.case_id
  }
  length  = 20
  special = false
  upper   = true
}
#
#
# Storage Pool
#
# DFIR Pool
resource "libvirt_pool" "case_pool" {
  name = var.case_id
  type = "dir"
  target {
    path = format("%s/%s", var.dfir_pool_base_path, var.case_id)
  }
}
#
#
# Network
#
# Case Network
resource "libvirt_network" "case_network" {
  name      = var.case_id
  mode      = "none"
  domain    = local.case_nwk_domain
  autostart = true
  addresses = ["${var.nwk_addr}/${var.nwk_cidr}"]
  dhcp {
    enabled = true
  }
  dns {
    enabled    = true
    local_only = true
    forwarders {
      address = local.case_nwk_gateway
    }
    hosts {
      hostname = local.fqdn_gateway
      ip       = local.case_nwk_gateway
    }
  }
  dnsmasq_options {
    options {
      option_name  = "dhcp-option"
      option_value = "option:router,${local.case_nwk_gateway}"
    }
    options {
      option_name  = "dhcp-range"
      option_value = "${local.case_nwk_dhcp_first},${local.case_nwk_dhcp_last},${local.case_nwk_netmask}"
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
        distro_release  = var.sw_alpine_release
        nameserver      = var.access_nwk_dns
        internal_domain = local.case_nwk_domain
        internal_dns    = local.case_nwk_localdns
        internal_net    = var.nwk_addr
        internal_addr   = local.case_nwk_gateway
        internal_cidr   = var.nwk_cidr
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
  size             = var.gateway_root
  pool             = libvirt_pool.case_pool.name
  base_volume_id   = var.sw_alpine_image_id
  base_volume_pool = var.base_image_pool_id
}
# gateway domain
resource "libvirt_domain" "gateway" {
  name      = "${var.case_id}-gateway"
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
    network_id = var.access_nwk_id
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
        distro_release = var.sw_debian_release
        gateway_addr   = local.access_nwk_gateway
        internal_net   = var.nwk_addr
        internal_cidr  = var.nwk_cidr
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
  size             = var.bastion_root
  pool             = libvirt_pool.case_pool.name
  base_volume_id   = var.sw_debian_image_id
  base_volume_pool = var.base_image_pool_id
}
# bastion domain
resource "libvirt_domain" "bastion" {
  name      = "${var.case_id}-bastion"
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
    network_id     = var.access_nwk_id
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
        distro_release = var.sw_debian_release
        internal_net   = var.nwk_addr
        internal_cidr  = var.nwk_cidr
        users          = local.users_case_vms
        case_id        = var.case_id
        ts_admuser     = local.timesketch_admuser
        ts_admpass     = local.timesketch_admpass
        ts_user        = local.timesketch_user
        ts_pass        = local.timesketch_pass
        ts_version     = var.timesketch_version
        ts_nb_version  = var.notebook_version
        ts_nb_port     = local.jupyter_port
        plaso_version  = var.plaso_version
      }
    )
  }
  part {
    filename = "timesketch_template.ipynb"
    content = templatefile(
      "${path.module}/jupyter/ts_nb_template.tftpl",
      {
        fqdn    = local.fqdn_worker
        case_id = var.case_id
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
  size             = var.worker_root
  pool             = libvirt_pool.case_pool.name
  base_volume_id   = var.sw_debian_image_id
  base_volume_pool = var.base_image_pool_id
}
# worker data volume
resource "libvirt_volume" "worker_data" {
  name   = "worker-data.qcow2"
  format = "qcow2"
  size   = var.worker_data
  pool   = libvirt_pool.case_pool.name
}
# worker domain
resource "libvirt_domain" "worker" {
  name = "${var.case_id}-worker"
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
        distro_release = var.sw_debian_release
        internal_net   = var.nwk_addr
        internal_cidr  = var.nwk_cidr
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
  size             = var.siftstation_root
  pool             = libvirt_pool.case_pool.name
  base_volume_id   = var.sw_debian_image_id
  base_volume_pool = var.base_image_pool_id
}
# siftstation domain
resource "libvirt_domain" "siftstation" {
  name = "${var.case_id}-siftstation"
  depends_on = [
    #libvirt_domain.worker,
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
