provider "digitalocean" {
  token = "${var.tectonic_do_token}"
}

module "etcd" {
  source = "../../modules/digitalocean/etcd"

  droplet_count = "${var.tectonic_etcd_count > 0 ? var.tectonic_etcd_count : 3}"
  droplet_size = "${var.tectonic_do_etcd_droplet_size}"
  droplet_region = "${var.tectonic_do_droplet_region}"
  droplet_image = "${var.tectonic_do_droplet_image}"
  container_image = "${var.tectonic_container_images["etcd"]}"
  cluster_name = "${var.tectonic_cluster_name}"
  cluster_domain = "${var.tectonic_cluster_name}.k8s.${var.tectonic_base_domain}"
  ssh_keys = "${var.tectonic_do_ssh_keys}"
  extra_tags = "${var.tectonic_do_extra_tags}"
  droplet_region = "${var.tectonic_do_droplet_region}"
  droplet_image = "${var.tectonic_do_droplet_image}"
  swap_size = "${var.tectonic_do_etcd_swap}"
  tls_enabled = "${var.tectonic_etcd_tls_enabled}"
  tls_zip = "${module.etcd_certs.etcd_tls_zip}"
}

module "ignition_masters" {
  source = "../../modules/digitalocean/ignition"

  container_images = "${var.tectonic_container_images}"
  swap_size = "${var.tectonic_do_master_swap}"
  cluster_domain = "${var.tectonic_cluster_name}.k8s.${var.tectonic_base_domain}"
  kube_dns_service_ip = "${module.bootkube.kube_dns_service_ip}"
  kubelet_node_label = "node-role.kubernetes.io/master"
  kubelet_node_taints = "node-role.kubernetes.io/master=:NoSchedule"
  tectonic_service_disabled = "${var.tectonic_vanilla_k8s}"
}

module "masters" {
  source = "../../modules/digitalocean/master"

  droplet_size = "${var.tectonic_do_master_droplet_size}"
  droplet_region = "${var.tectonic_do_droplet_region}"
  droplet_image = "${var.tectonic_do_droplet_image}"
  cluster_name = "${var.tectonic_cluster_name}"
  ssh_keys = "${var.tectonic_do_ssh_keys}"
  extra_tags = "${var.tectonic_do_extra_tags}"
  user_data = "${module.ignition_masters.ignition}"
  cluster_domain = "${var.tectonic_cluster_name}.k8s.${var.tectonic_base_domain}"
}

module "ignition_workers" {
  source = "../../modules/digitalocean/ignition"

  kubelet_node_label = "node-role.kubernetes.io/node"
  kubelet_node_taints = ""
  kube_dns_service_ip = "${module.bootkube.kube_dns_service_ip}"
  container_images = "${var.tectonic_container_images}"
  swap_size = "${var.tectonic_do_worker_swap}"
  cluster_domain = "${var.tectonic_cluster_name}.k8s.${var.tectonic_base_domain}"
}

module "workers" {
  source = "../../modules/digitalocean/worker"

  droplet_count = "${var.tectonic_worker_count}"
  cluster_name = "${var.tectonic_cluster_name}"
  droplet_size = "${var.tectonic_do_worker_droplet_size}"
  droplet_region = "${var.tectonic_do_droplet_region}"
  droplet_image = "${var.tectonic_do_droplet_image}"
  ssh_keys = "${var.tectonic_do_ssh_keys}"
  user_data = "${module.ignition_workers.ignition}"
  extra_tags = "${var.tectonic_do_extra_tags}"
  cluster_domain = "${module.masters.cluster_fqdn}"
}
