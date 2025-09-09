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
  #uri  = "qemu+ssh://ice@saturn/system?keyfile=id_ecdsa"
  uri = "qemu:///system"
}
#
#
# User Config
# generate a password like this:
# echo -en "passw0rd" | mkpasswd -m sha512crypt --stdin
# CONFIGURE USERS IN `users-gateway.json` AND `users-case-vms.json`!
#
#
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
  name = "base"
  type = "dir"
  path = "/var/lib/libvirt/images/base"
}
# DFIR Pool
dfir_pool_config = {
  name      = "dfir"
  base_path = "/var/lib/libvirt/images/dfir"
}
