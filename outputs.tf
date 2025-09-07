# Terraform Outputs
# vim: set expandtab ts=2 sw=2 ft=terraform:
#
# Prepare some information to pass to the users
#
# Case configs
output "case_configs" {
  description = "Case Configurations"
  value = {
    for c in var.cases : "${c.case_type}-${c.case_code}-${c.case_date}" => {
      "ssh_bastion"             = format("%s%s", "ssh -D <proxyport> -N -f -l <user> ", module.case["${c.case_type}-${c.case_code}-${c.case_date}"].fqdn_bastion)
      "ssh_worker"              = format("%s%s", "ssh -i <sshkey> -l <user> -o ProxyCommand='nc -x 127.0.0.1:<proxyport> %h %p' ", module.case["${c.case_type}-${c.case_code}-${c.case_date}"].fqdn_worker)
      "ssh_siftstation"         = format("%s%s", "ssh -i <sshkey> -l <user> -o ProxyCommand='nc -x 127.0.0.1:<proxyport> %h %p' ", module.case["${c.case_type}-${c.case_code}-${c.case_date}"].fqdn_siftstation)
      "web_timesketch"          = format("%s%s", "http://", module.case["${c.case_type}-${c.case_code}-${c.case_date}"].fqdn_worker)
      "web_notebook"            = format("%s%s%s", "http://", module.case["${c.case_type}-${c.case_code}-${c.case_date}"].fqdn_worker, ":8844/?token=timesketch")
      "userpass_timesketch_adm" = format("%s/%s", module.case["${c.case_type}-${c.case_code}-${c.case_date}"].ts_admuser, module.case["${c.case_type}-${c.case_code}-${c.case_date}"].ts_admpass)
      "userpass_timesketch_usr" = format("%s/%s", module.case["${c.case_type}-${c.case_code}-${c.case_date}"].ts_user, module.case["${c.case_type}-${c.case_code}-${c.case_date}"].ts_pass)
    }
  }
}
