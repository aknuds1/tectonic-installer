provider "digitalocean" {
  token = "${var.tectonic_do_token}"
}

module "etcd" {
  source = "../../modules/digitalocean/etcd"

  droplet_count = "${var.tectonic_etcd_count > 0 ? var.tectonic_etcd_count : 3}"
  droplet_size = "${var.tectonic_do_etcd_droplet_size}"
  container_image = "${var.tectonic_container_images["etcd"]}"
  cluster_name = "${var.tectonic_cluster_name}"
  base_domain = "${var.tectonic_base_domain}"
  ssh_keys = "${var.tectonic_do_ssh_keys}"
  extra_tags = "${var.tectonic_do_extra_tags}"
}
