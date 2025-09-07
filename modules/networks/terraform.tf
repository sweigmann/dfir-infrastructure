# Terraform Configuration
# vim: set expandtab ts=2 sw=2 ft=terraform:
#
# Providers
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">=0.8.3"
    }
  }
}
