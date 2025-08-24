# Terraform Outputs
# vim: set expandtab ts=2 sw=2 ft=terraform:
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
