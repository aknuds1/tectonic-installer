resource "digitalocean_domain" "etc_nodes" {
  count = "${var.droplet_count}"
  name = "${var.cluster_name}-etcd-${count.index}.${var.base_domain}"
  ip_address = "${digitalocean_droplet.etcd_node.*.ipv4_address[count.index]}"
}

resource "digitalocean_record" "etcd_srv_discover" {
  count = "${var.droplet_count}"
  type = "SRV"
  name = "_etcd-server._tcp"
  domain = "${var.base_domain}"
  value = "0 0 2380 ${element(digitalocean_domain.etc_nodes.*.id, count.index)}"
}

resource "digitalocean_record" "etcd_srv_client" {
  count = "${var.droplet_count}"
  type = "SRV"
  name = "_etcd-client._tcp"
  domain = "${var.base_domain}"
  value = "0 0 2379 ${element(digitalocean_domain.etc_nodes.*.id, count.index)}"
}
