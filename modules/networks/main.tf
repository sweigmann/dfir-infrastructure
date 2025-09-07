# Terraform Module: networks
# vim: set expandtab ts=2 sw=2 ft=terraform:
#
#
# Access Network (Bastion Hosts)
resource "libvirt_network" "access_network" {
  name      = "access-net"
  mode      = "route"
  domain    = var.access_network_domain
  autostart = true
  addresses = var.access_network_addresses
  dhcp {
    enabled = true
  }
  dns {
    enabled    = true
    local_only = true
    forwarders {
      address = var.access_network_external_dns
    }
    /*
    forwarders {
      domain  = local.case_network_domain
      address = local.case_network_localdns
    }
    */
    dynamic "forwarders" {
      for_each = var.access_network_external_forwarders
      content {
        domain  = forwarders.key
        address = forwarders.value
      }
    }
  }
  dnsmasq_options {
    options {
      option_name  = "listen-address"
      option_value = var.access_network_external_addr
    }
  }
}
