resource "digitalocean_domain" "etc_nodes" {
  count = "${var.droplet_count}"
  name = "${var.cluster_name}-etcd-${count.index}.${var.base_domain}"
  ip_address = "${digitalocean_droplet.etcd_node.*.ipv4_address[count.index]}"
}

resource "digitalocean_record" "etcd_srv_discover" {
  count = "${var.droplet_count}"
  type = "SRV"
  domain = "${element(digitalocean_domain.etc_nodes.*.id, count.index)}"
  name = "_etcd-server._tcp"
  port = 2380
  weight = 0
  priority = 0
}

resource "digitalocean_record" "etcd_srv_client" {
  count = "${var.droplet_count}"
  type = "SRV"
  domain = "${element(digitalocean_domain.etc_nodes.*.id, count.index)}"
  name = "_etcd-client._tcp"
  port = 2379
  weight = 0
  priority = 0
}
