variable "base_domain" {
  type = "string"
}

variable "cluster_name" {
  type = "string"
}

variable "container_image" {
  type = "string"
}

variable "container_linux_channel" {
  type = "string"
}

variable "container_linux_version" {
   type = "string"
}

variable "droplet_count" {
  default = "3"
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

variable "ssh_keys" {
  type = "list"
}

variable "tls_enabled" {
  default = false
}

variable "tls_zip" {
  type = "string"
}
