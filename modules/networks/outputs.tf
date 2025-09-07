# Terraform Module: networks
# vim: set expandtab ts=2 sw=2 ft=terraform:
#
#
output "access_network_id" {
  value = libvirt_network.access_network.id
}
