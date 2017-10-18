variable "base_domain" {
  type = "string"
}

variable "cluster_name" {
  type = "string"
}

variable "container_linux_channel" {
  type = "string"
}

variable "container_linux_version" {
   type = "string"
}

variable "droplet_count" {
  type = "string"
}

variable "droplet_region" {
  type = "string"
}

variable "droplet_size" {
  type = "string"
}

variable "extra_tags" {
  type = "list"
}

variable "ssh_keys" {
  type = "list"
}
