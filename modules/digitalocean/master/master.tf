resource "digitalocean_floating_ip" "master" {
  region = "${var.droplet_region}"
  droplet_id = "${digitalocean_droplet.master_node.id}"
}

resource "null_resource" "tectonic_assets" {
  # Changes to any asset requires re-provisioning
  triggers {
    assets = "${var.assets_id}"
  }

  provisioner "local-exec" {
    command = "./generated/bin/do-pusher.sh ${var.assets_path} ${var.spaces_bucket}/assets.zip"
  }
}

resource "null_resource" "kubeconfig" {
  triggers {
    assets = "${var.kubeconfig_id}"
  }
}

resource "digitalocean_droplet" "master_node" {
  count      = "${var.master_count}"
# depends_on = ["null_resource.tectonic_assets", "null_resource.kubeconfig"]
#  Can we do this a better way?
#  What Tectonic Assets does this resource depend on that others do not?
  name       = "${var.cluster_name}-master-${count.index}"
  image      = "${var.droplet_image}"
  region     = "${var.droplet_region}"
  size       = "${var.droplet_size}"
  ssh_keys   = ["${var.ssh_keys}"]
  tags       = ["${var.extra_tags}"]
  user_data  = "${data.ignition_config.main.rendered}"

}
