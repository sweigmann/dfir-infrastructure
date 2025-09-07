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
# Case Configurations
cases = [
  {
    # case id
    case_type = "df"
    case_code = "submarine"
    case_date = "20250327"
    # case network
    network_addr = "10.10.10.0"
    network_cidr = "24"
    # last known good software combo:
    #software_tag.plaso       = "20241006"
    #software_tag.timesketch = "20241129"
    ## Notebook build datetime: Dec 19, 2024, 3:40:20 PM
    ##software_tag.ts_notebook = "sha256:4ca1d875c49b3e8ba2fa55d3776bcbd586b9dcf8a3537db4dcc6c07e8f5c3844"
    software_plaso = "20250522"
    # Timesketch versions:
    # 20250807: ERROR - cannot connect to opensearch
    # 20250708: WORKS
    # 20250521:
    # 20250408:
    # 20250112:
    # 20241129: WORKS
    software_timesketch = "20250708"
    # Notebook build datetime: Dec 19, 2024, 3:40:20 PM
    software_notebook = "sha256:4ca1d875c49b3e8ba2fa55d3776bcbd586b9dcf8a3537db4dcc6c07e8f5c3844"
    # volumes
    volsize_bastion_root     = 4000000000
    volsize_gateway_root     = 2000000000
    volsize_worker_root      = 20000000000
    volsize_worker_data      = 100000000000
    volsize_siftstation_root = 10000000000
  },
  {
    case_type                = "ir"
    case_code                = "doublesanta"
    case_date                = "20241225"
    network_addr             = "10.10.20.0"
    network_cidr             = "24"
    software_plaso           = "20250522"
    software_timesketch      = "20250708"
    software_notebook        = "sha256:4ca1d875c49b3e8ba2fa55d3776bcbd586b9dcf8a3537db4dcc6c07e8f5c3844"
    volsize_bastion_root     = 4000000000
    volsize_gateway_root     = 2000000000
    volsize_worker_root      = 20000000000
    volsize_worker_data      = 100000000000
    volsize_siftstation_root = 10000000000
  }
]
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
