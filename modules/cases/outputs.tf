# Terraform Module: cases
# vim: set expandtab ts=2 sw=2 ft=terraform:
#
#
output "fqdn_bastion" {
  value = local.fqdn_bastion
}
output "fqdn_gateway" {
  value = local.fqdn_gateway
}
output "fqdn_worker" {
  value = local.fqdn_worker
}
output "fqdn_siftstation" {
  value = local.fqdn_siftstation
}
output "ts_admuser" {
  value = local.timesketch_admuser
}
output "ts_admpass" {
  value = local.timesketch_admpass
}
output "ts_user" {
  value = local.timesketch_user
}
output "ts_pass" {
  value = local.timesketch_pass
}
