resource "digitalocean_domain" "etcd_nodes" {
  count = "${var.droplet_count}"
  name = "${var.cluster_name}-etcd-${count.index}.${var.base_domain}"
  ip_address = "${digitalocean_droplet.etcd_node.*.ipv4_address[count.index]}"
}
