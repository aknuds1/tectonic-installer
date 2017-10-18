resource "digitalocean_droplet" "worker_node" {
  count     = "${var.droplet_count}"
  name      = "${var.cluster_name}-worker-${count.index}"
  image     = "coreos-${var.container_linux_channel}"
  region    = "${var.droplet_region}"
  size      = "${var.droplet_size}"
  ssh_keys  = ["${var.ssh_keys}"]
  tags      = ["${var.extra_tags}"]
  user_data = "${data.ignition_config.main.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}
