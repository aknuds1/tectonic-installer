# Create separate domain for etcd nodes, because depending on main cluster domain would cause
# a dependency cycle, as the latter must be instantiated with the API server IP address
resource "digitalocean_domain" "etcd" {
  name = "etcd.${var.base_domain}"
  ip_address = "${digitalocean_droplet.etcd_node.*.ipv4_address[0]}"
}

resource "digitalocean_record" "etcd_nodes" {
  count = "${var.droplet_count}"
  domain = "${digitalocean_domain.etcd.id}"
  type = "A"
  name = "etcd-${count.index}"
  value = "${digitalocean_droplet.etcd_node.*.ipv4_address[count.index]}"
}
