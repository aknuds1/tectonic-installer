variable "assets_id" {
  type = "string"
}

variable "assets_path" {
  type = "string"
}

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

variable "do_pusher_id" {
  type = "string"
}

variable "do_token" {
  type = "string"
}

variable "droplet_image" {
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

variable "ign_bootkube_path_unit_id" {
  type = "string"
}

variable "ign_bootkube_service_id" {
  type        = "string"
  description = "The ID of the bootkube systemd service unit"
}

variable "ign_do_puller_id" {
  type = "string"
}

variable "ign_init_assets_service_id" {
  type = "string"
}

variable "ign_resolved_conf_id" {
  type = "string"
}

variable "ign_rm_assets_path_unit_id" {
  type = "string"
}

variable "ign_rm_assets_service_id" {
  type = "string"
}

variable "ign_tectonic_path_unit_id" {
  type = "string"
}

variable "ign_tectonic_service_id" {
  type        = "string"
  description = "The ID of the tectonic installer systemd service unit"
}

variable "image_re" {
  description = "(internal) Regular expression used to extract repo and tag components from image strings"
  type        = "string"
}

variable "kubeconfig_id" {
  type = "string"
}

variable "master_count" {
  type    = "string"
  default = 1
}

variable "spaces_bucket" {
  type        = "string"
  description = "Spaces bucket containing files"
}

variable "ssh_keys" {
  type = "list"
}
