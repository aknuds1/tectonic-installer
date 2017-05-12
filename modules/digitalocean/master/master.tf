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

resource "digitalocean_domain" "api-external" {
  count = 1
  name = "${var.cluster_name}-api.${var.base_domain}"
  # TODO: Introduce load balancer
  ip_address = "${digitalocean_droplet.master_node.*.ipv4_address[0]}"
}
