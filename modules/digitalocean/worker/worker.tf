resource "digitalocean_droplet" "worker_node" {
  count     = "${var.droplet_count}"
  name      = "${var.cluster_name}-worker-${count.index}"
  image     = "${var.droplet_image}"
  region    = "${var.droplet_region}"
  size      = "${var.droplet_size}"
  ssh_keys  = ["${var.ssh_keys}"]
  tags      = ["${var.extra_tags}"]
  user_data = "${data.ignition_config.main.rendered}"

  volume_ids = [
    "${element(concat(digitalocean_volume.worker.*.id, list("")), count.index)}",
  ]
}

resource "digitalocean_record" "worker" {
  count  = "${var.droplet_count}"
  domain = "${var.base_domain}"
  type   = "A"
  name   = "${var.cluster_name}-worker-${count.index}"
  value  = "${element(digitalocean_droplet.worker_node.*.ipv4_address, count.index)}"
}

resource "digitalocean_volume" "worker" {
  count  = "${var.volume_size != 0 ? var.droplet_count : 0}"
  region = "${var.droplet_region}"
  name   = "${var.cluster_name}-worker-${count.index}"
  size   = "${var.volume_size}"
}
