# Terraform Configuration
# vim: set expandtab ts=2 sw=2 ft=terraform:
#
# Providers
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">=2.3.7"
    }
    time = {
      source  = "hashicorp/time"
      version = ">=0.13.1"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.7.2"
    }
  }
}
