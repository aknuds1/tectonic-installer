variable "base_domain" {
  type = "string"
}

variable "cluster_name" {
  type = "string"
}

variable "container_images" {
  description = "Container images to use"
  type        = "map"
}

variable "container_linux_channel" {
  type = "string"
}

variable "container_linux_version" {
   type = "string"
}

variable "droplet_region" {
  type = "string"
}

variable "droplet_size" {
  type = "string"
}

variable "extra_tags" {
  type    = "list"
  default = []
}

variable "image_re" {
  description = "(internal) Regular expression used to extract repo and tag components from image strings"
  type        = "string"
}

variable "master_count" {
  default = 1
}

variable "ssh_keys" {
  type = "list"
}

variable "ign_init_assets_service_id" {
  type = "string"
}

variable "ign_bootkube_path_unit_id" {
  type = "string"
}

variable "ign_bootkube_service_id" {
  type        = "string"
  description = "The ID of the bootkube systemd service unit"
}

variable "ign_tectonic_path_unit_id" {
  type = "string"
}

variable "ign_tectonic_service_id" {
  type        = "string"
  description = "The ID of the tectonic installer systemd service unit"
}
