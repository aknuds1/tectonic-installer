variable "cluster_name" {
  type = "string"
}

variable "droplet_size" {
  type = "string"
}

variable "extra_tags" {
  type = "list"
  default = []
}

variable "ssh_keys" {
  type = "list"
}

variable "droplet_region" {
  type = "string"
}

variable "droplet_image" {
  type = "string"
}

variable "user_data" {
  type = "string"
}

variable "base_domain" {
  type = "string"
}
