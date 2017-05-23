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

resource "digitalocean_domain" "cluster" {
  name = "${var.cluster_domain}"
  # TODO: Introduce load balancer when having multiple master nodes
  ip_address = "${digitalocean_droplet.master_node.*.ipv4_address[0]}"
}
