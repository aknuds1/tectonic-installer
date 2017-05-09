variable "cluster_name" {
  type = "string"
}

variable "base_domain" {
  type = "string"
}

variable "droplet_count" {
  default = "3"
}

variable "droplet_size" {
  type = "string"
}

variable "extra_tags" {
  type = "list"
  default = []
}

variable "container_image" {
  type = "string"
}

variable "ssh_keys" {
  type = "list"
}

variable "dns_zone_id" {
  type = "string"
}