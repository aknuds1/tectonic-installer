resource "digitalocean_record" "etcd_nodes" {
  count  = "${var.droplet_count}"
  domain = "${var.base_domain}"
  type   = "A"
  name   = "${var.cluster_name}-etcd-${count.index}"
  value  = "${digitalocean_droplet.etcd_node.*.ipv4_address[count.index]}"
}
