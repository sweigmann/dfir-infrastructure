# Terraform Module: images
# vim: set expandtab ts=2 sw=2 ft=terraform:
#
#
# Base Image Storage Pool Configuration
resource "libvirt_pool" "base_pool" {
  name = var.base_pool_name
  type = var.base_pool_type
  target {
    path = var.base_pool_path
  }
}
#
#
# Configure QCOW2 image sources
#
# Alpine Linux v3.xx
resource "libvirt_volume" "alpine_v3" {
  name   = "alpine-${var.base_image_alpine_v3_release}-x86_64.${var.base_image_alpine_v3_format}"
  format = var.base_image_alpine_v3_format
  source = var.base_image_alpine_v3_source
  pool   = libvirt_pool.base_pool.name
}
#
# Debian Trixie
resource "libvirt_volume" "debian_trixie" {
  name   = "debian-${var.base_image_debian_trixie_release}-generic-amd64.${var.base_image_debian_trixie_format}"
  format = var.base_image_debian_trixie_format
  source = var.base_image_debian_trixie_source
  pool   = libvirt_pool.base_pool.name
}
