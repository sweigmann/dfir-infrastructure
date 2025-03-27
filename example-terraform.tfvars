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
user_config = {
  username  = "dfir-user"
  usergecos = "DFIR user"
  password  = "$6$GjmdsnrKG02hsWmz$H7b17il3X0qNp7SdC.0Rj1dZijz7OSENz6NtRLVsnAJqeVE.Bf.YW5Y0yCFSEhbe5mcIa2Pd0LQ86jAduI73S."
  ssh_key   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcqdebJG6shtN9g6nxeDFQxkqLnJ2q7/wMM5eK11U0o dfir-user@laptop"
}
#
#
# Network Config
case_network = {
  addresses     = ["10.10.10.0/29"]
  domain        = "incident-responders.org"
  external_addr = "192.168.0.1"
}
#
#
# Pool Configs
#
# Base Image Pool
base_pool_config = {
  name = "base_images"
  path = "/var/lib/libvirt/images/base_images"
}
# DFIR Pool
dfir_pool_config = {
  name = "dfir_images"
  base_path = "/var/lib/libvirt/images/dfir"
}
