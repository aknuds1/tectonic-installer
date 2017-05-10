resource "digitalocean_droplet" "master_node" {
  count = 1
  name = "${var.cluster_name}-master-${count.index}"
  image = "${var.droplet_image}"
  region = "${var.droplet_region}"
  size = "${var.droplet_size}"
  ssh_keys = ["${var.ssh_keys}"]
  tags = ["${var.extra_tags}"]
  user_data = "${var.user_data}"
}

resource "aws_route53_record" "api-external" {
  count = 1
  zone_id = "${var.dns_zone_id}"
  name = "${var.cluster_name}-api.${var.base_domain}"
  type = "A"
  ttl = "60"
  # TODO: Introduce load balancer
  records = ["${digitalocean_droplet.master_node.*.ipv4_address[0]}"]
}
