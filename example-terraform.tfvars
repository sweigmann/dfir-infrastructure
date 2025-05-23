# Terraform Variable definitions
# vim: set expandtab ts=2 sw=2 ft=terraform:
#
# MUST READ:
# * https://github.com/dmacvicar/terraform-provider-libvirt/issues/546#issuecomment-612983090
# * https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config
#
#
# Libvirt Provider Configuration
# https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs/
libvirt_config = {
  name = "dfirhost"
  uri  = "qemu+ssh://kvmuser@dfirhost/system?keyfile=id_ecdsa"
  #uri  = "qemu:///system"
}
#
#
# Case Config
case_config = {
  type = "ir"
  code = "submarine"
  date = "20250327"
}
#
#
# User Config
# generate a password like this:
# echo -en "passw0rd" | mkpasswd -m sha512crypt --stdin
# CONFIGURE USERS IN `users-gateway.json` AND `users-case-vms.json`!
#
#
# Network Configs
#
# Access Network
#
access_network = {
  addresses     = ["192.168.66.0/29"]
  domain        = "incident-responders.org"
  external_addr = "192.168.0.1"
  external_dns  = "8.8.8.8"
}
# Case Network
case_network = {
  network_addr = "10.10.10.0"
  network_cidr = "24"
}
#
#
# Tags and versions for software
software_tag = {
  plaso      = "20241006"
  timesketch = "20241129"
  # Notebook build datetime: Dec 19, 2024, 3:40:20 PM
  ts_notebook = "sha256:4ca1d875c49b3e8ba2fa55d3776bcbd586b9dcf8a3537db4dcc6c07e8f5c3844"
}
#
#
# Volume sizes (in Bytes)
volume_size = {
  bastion_root     = 4000000000
  gateway_root     = 2000000000
  worker_root      = 20000000000
  worker_data      = 150000000000
  siftstation_root = 10000000000
}
#
#
# Semi-static configurations
# You likely would not need to change anything below here
#
#
# Pool Configs
#
# Base Image Pool
base_pool_config = {
  name = "base_images"
  path = "/var/lib/libvirt/images/base_images"
}
# Bastion Pool
bastion_pool_config = {
  name      = "bastion_images"
  base_path = "/var/lib/libvirt/images/bastion"
}
# DFIR Pool
dfir_pool_config = {
  name      = "dfir_images"
  base_path = "/var/lib/libvirt/images/dfir"
}
