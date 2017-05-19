resource "digitalocean_droplet" "worker_node" {
  count = "${var.instance_count}"
  name = "${var.cluster_name}-worker-${count.index}"
  image = "${var.droplet_image}"
  region = "${var.droplet_region}"
  size = "${var.droplet_size}"
  ssh_keys = ["${var.ssh_keys}"]
  tags = ["${var.extra_tags}"]
  user_data = "${var.user_data}"
}
