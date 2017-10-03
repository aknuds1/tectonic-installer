variable "droplet_count" {
  type = "string"
}

variable "cluster_name" {
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

variable "ssh_keys" {
  type = "list"
}

variable "extra_tags" {
  type = "list"
}

# variable "user_data" {
#   type = "string"
# }

variable "base_domain" {
  type = "string"
}
