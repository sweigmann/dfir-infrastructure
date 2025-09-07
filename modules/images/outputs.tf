# Terraform Module: images
# vim: set expandtab ts=2 sw=2 ft=terraform:
#
#
# Base Image Storage Pool Configuration
#
# Pool ID
output "pool_id" {
  value = libvirt_pool.base_pool.id
}
#
# Alpine Linux v3.xx
# Volume ID
output "volume_alpine_v3_id" {
  value = libvirt_volume.alpine_v3.id
}
# Release
output "volume_alpine_v3_release" {
  value = var.base_image_alpine_v3_release
}
#
# Debian Trixie
# Volume ID
output "volume_debian_trixie_id" {
  value = libvirt_volume.debian_trixie.id
}
# Release
output "volume_debian_trixie_release" {
  value = var.base_image_debian_trixie_release
}
