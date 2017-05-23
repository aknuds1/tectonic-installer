variable "container_images" {
  description = "Container images to use"
  type = "map"
}

variable "kube_dns_service_ip" {
  type = "string"
  description = "Service IP used to reach kube-dns"
}

variable "kubelet_node_label" {
  type = "string"
  description = "Label that Kubelet will apply on the node"
}

variable "kubelet_node_taints" {
  type = "string"
  description = "Taints that Kubelet will apply on the node"
}

variable "bootkube_service" {
  type = "string"
  description = "The content of the bootkube systemd service unit"
}

variable "swap_size" {
  type = "string"
  description = "The amount of swap memory to enable"
}

variable "base_domain" {
  type = "string"
  description = "The base domain"
}

# variable "tectonic_service" {
#   type = "string"
#   description = "The content of the tectonic installer systemd service unit"
# }
#
# variable "tectonic_service_disabled" {
#   description = "Specifies whether the tectonic installer systemd unit will be disabled. If true, no tectonic assets will be deployed"
#   default = false
# }
