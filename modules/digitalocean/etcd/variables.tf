variable "cluster_name" {
  type = "string"
}

variable "cluster_domain" {
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

variable "droplet_region" {
  type = "string"
}

variable "droplet_image" {
  type = "string"
}

variable "swap_size" {
  type = "string"
  description = "Amount of swap memory to enable"
}

variable "tls_enabled" {
}

variable "tls_ca_crt_pem" {
  type = "string"
}

variable "tls_client_key_pem" {
  type = "string"
}

variable "tls_client_crt_pem" {
  type = "string"
}

variable "tls_peer_key_pem" {
  type = "string"
}

variable "tls_peer_crt_pem" {
  type = "string"
}
