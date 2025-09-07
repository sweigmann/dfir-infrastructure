# Terraform Module: images
# vim: set expandtab ts=2 sw=2 ft=terraform:
#
#
# Base Image Storage Pool Configuration
/*
# THIS DOES NOT WORK
#   getting errors when referencing from parent:
#     base_pool.name = "myname"
variable "base_pool" {
  description = "Storage pool for base images"
  type = object({
    name = string
    type = string
    path = string
  })
  default = {
    name = "base"
    type = "dir"
    path = "/var/lib/libvirt/images/base"
  }
}
*/
variable "base_pool_name" {
  description = "Storage pool for base images: name"
  type        = string
}
variable "base_pool_type" {
  description = "Storage pool for base images: type"
  type        = string
  default     = "dir"
}
variable "base_pool_path" {
  description = "Storage pool for base images: path"
  type        = string
  default     = "/var/lib/libvirt/images/base"
}
#
#
# Base Images
#
# Alpine
/*
# THIS DOES NOT WORK
#   see above
variable "base_image_alpine_v3" {
  description = "Image source for Alpine Linux v3.xx"
  type = object({
    name    = string
    release = string
    format  = string
    source  = string
  })
  default = {
    name    = "alpine-3.22.1-x86_64.qcow2"
    release = "v3.22"
    format  = "qcow2"
    source  = "http://dl-cdn.alpinelinux.org/alpine/v3.22/releases/cloud/generic_alpine-3.22.1-x86_64-bios-cloudinit-r0.qcow2"
  }
}
*/
variable "base_image_alpine_v3_name" {
  description = "Image source for Alpine Linux v3.xx: name"
  type        = string
}
variable "base_image_alpine_v3_release" {
  description = "Image source for Alpine Linux v3.xx: release"
  type        = string
}
variable "base_image_alpine_v3_format" {
  description = "Image source for Alpine Linux v3.xx: format"
  type        = string
}
variable "base_image_alpine_v3_source" {
  description = "Image source for Alpine Linux v3.xx: source"
  type        = string
}
#
# Debian
/*
# THIS DOES NOT WORK
#   see above
variable "base_image_debian_trixie" {
  description = "Image source for Debian Linux (Trixie)"
  type = object({
    name    = string
    release = string
    format  = string
    source  = string
  })
  default = {
    name    = "debian-13-generic-amd64.qcow2"
    release = "trixie"
    format  = "qcow2"
    source  = "http://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
  }
}
*/
variable "base_image_debian_trixie_name" {
  description = "Image source for Debian Linux (Trixie): name"
  type        = string
}
variable "base_image_debian_trixie_release" {
  description = "Image source for Debian Linux (Trixie): release"
  type        = string
}
variable "base_image_debian_trixie_format" {
  description = "Image source for Debian Linux (Trixie): format"
  type        = string
}
variable "base_image_debian_trixie_source" {
  description = "Image source for Debian Linux (Trixie): source"
  type        = string
}
