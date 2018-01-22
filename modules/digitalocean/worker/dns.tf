resource "digitalocean_record" "worker" {
  count  = "${var.worker_count}"
  domain = "${var.base_domain}"
  name   = "${var.cluster_name}-worker-${count.index}"
  type   = "A"
  ttl    = 300
  value  = "${element(digitalocean_droplet.worker_node.*.ipv4_address, count.index)}"
}
