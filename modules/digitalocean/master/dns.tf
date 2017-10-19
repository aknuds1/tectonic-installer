# resource "digitalocean_domain" "api" {
#   name   = "api.${var.cluster_name}.${var.base_domain}"
#   ip_address  = "${digitalocean_loadbalancer.api.ip}"
# }

resource "digitalocean_domain" "console" {
  name       = "console.${var.cluster_name}.${var.base_domain}"
  ip_address = "${digitalocean_loadbalancer.console.ip}"
}

resource "digitalocean_record" "master" {
  count  = "${var.master_count}"
  domain = "${var.base_domain}"
  name   = "${var.cluster_name}-master-${count.index}"
  type   = "A"
  ttl    = 300
  value  = "${element(digitalocean_droplet.master_node.*.ipv4_address, count.index)}"
}
