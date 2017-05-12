resource "digitalocean_droplet" "etcd_node" {
  count = "${var.droplet_count}"
  name = "${var.cluster_name}-etcd-${count.index}"
  image = "coreos-stable"
  region = "fra1"
  size = "${var.droplet_size}"
  ssh_keys = ["${var.ssh_keys}"]
  #tags = ["${var.extra_tags}"]
  user_data = "${data.ignition_config.etcd.*.rendered[count.index]}"
}
