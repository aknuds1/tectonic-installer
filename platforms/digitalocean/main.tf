provider "digitalocean" {
  token = "${var.tectonic_do_token}"
}

module "container_linux" {
  source = "../../modules/container_linux"

  channel = "${var.tectonic_container_linux_channel}"
  version = "${var.tectonic_container_linux_version}"
}

module "etcd" {
  source = "../../modules/digitalocean/etcd"

  droplet_count = "${var.tectonic_etcd_count > 0 ? var.tectonic_etcd_count : 3}"
  droplet_size = "${var.tectonic_do_etcd_droplet_size}"
  droplet_region = "${var.tectonic_do_droplet_region}"
  droplet_image = "${var.tectonic_do_droplet_image}"
  container_image = "${var.tectonic_container_images["etcd"]}"
  cluster_name = "${var.tectonic_cluster_name}"
  base_domain = "${var.tectonic_base_domain}"
  ssh_keys = "${var.tectonic_do_ssh_keys}"
  extra_tags = "${var.tectonic_do_extra_tags}"
  droplet_region = "${var.tectonic_do_droplet_region}"
  droplet_image = "${var.tectonic_do_droplet_image}"
  swap_size = "${var.tectonic_do_etcd_swap}"
  tls_enabled = "${var.tectonic_etcd_tls_enabled}"
  tls_zip = "${module.etcd_certs.etcd_tls_zip}"
  container_linux_channel = "${module.tectonic_container_linux_channel}"
  container_linux_version = "${module.tectonic_container_linux_version}"
}

module "ignition_masters" {
  source = "../../modules/ignition"
  base_domain = "${var.tectonic_base_domain}"
  bootstrap_upgrade_cl = "${var.tectonic_bootstrap_upgrade_cl}"
  cluster_name  = "${var.tectonic_cluster_name}"
  container_images = "${var.tectonic_container_images}"
  etcd_advertise_name_list = "${data.template_file.etcd_hostname_list.*.rendered}"
  etcd_count  = "${length(data.template_file.etcd_hostname_list.*.id)}"
  etcd_initial_cluster_list = "${data.template_file.etcd_hostname_list.*.rendered}"
  etcd_tls_enabled  = "${var.tectonic_etcd_tls_enabled}"
  image_re  = "${var.tectonic_image_re}"
  swap_size = "${var.tectonic_do_master_swap}"
  kube_dns_service_ip = "${module.bootkube.kube_dns_service_ip}"
  kubelet_cni_bin_dir = "${var.tectonic_calico_network_policy ? "/var/lib/cni/bin" : "" }"
  kubelet_node_label = "node-role.kubernetes.io/master"
  kubelet_node_taints = "node-role.kubernetes.io/master=:NoSchedule"
  tectonic_vanilla_k8s = "${var.tectonic_vanilla_k8s}"
}

module "masters" {
  source = "../../modules/digitalocean/master"

  droplet_size = "${var.tectonic_do_master_droplet_size}"
  droplet_region = "${var.tectonic_do_droplet_region}"
  droplet_image = "${var.tectonic_do_droplet_image}"
  cluster_name = "${var.tectonic_cluster_name}"
  ssh_keys = "${var.tectonic_do_ssh_keys}"
  extra_tags = "${var.tectonic_do_extra_tags}"
  #user_data = "${module.ignition_masters.ignition}"
  base_domain = "${var.tectonic_base_domain}"
  container_linux_channel = "${module.tectonic_container_linux_channel}"
  container_linux_version = "${module.tectonic_container_linux_version}"
}

module "ignition_workers" {
  source = "../../modules/ignition"

  bootstrap_upgrade_cl = "${var.tectonic_bootstrap_upgrade_cl}"
  container_images = "${var.tectonic_container_images}"
  image_re  = "${var.tectonic_image_re}"
  kube_dns_service_ip = "${module.bootkube.kube_dns_service_ip}"
  kubelet_cni_bin_dir = "${var.tectonic_calico_network_policy ? "/var/lib/cni/bin" : ""}"
  kubelet_node_label = "node-role.kubernetes.io/node"
  kubelet_node_taints = ""
  tectonic_vanilla_k8s = "${var.tectonic_vanilla_k8s}"
  swap_size = "${var.tectonic_do_worker_swap}"
}

module "workers" {
  source = "../../modules/digitalocean/worker"

  droplet_count = "${var.tectonic_worker_count}"
  cluster_name = "${var.tectonic_cluster_name}"
  droplet_size = "${var.tectonic_do_worker_droplet_size}"
  droplet_region = "${var.tectonic_do_droplet_region}"
  droplet_image = "${var.tectonic_do_droplet_image}"
  ssh_keys = "${var.tectonic_do_ssh_keys}"
  #user_data = "${module.ignition_workers.ignition}"
  extra_tags = "${var.tectonic_do_extra_tags}"
  base_domain = "${var.tectonic_base_domain}"
  container_linux_channel = "${module.tectonic_container_linux_channel}"
  container_linux_version = "${module.tectonic_container_linux_version}"
}
