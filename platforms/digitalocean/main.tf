provider "digitalocean" {
  version = "~> 0.1"

  token = "${var.tectonic_do_token}"
}

module "container_linux" {
  source = "../../modules/container_linux"

  channel = "${var.tectonic_container_linux_channel}"
  version = "${var.tectonic_container_linux_version}"
}

module "etcd" {
  source = "../../modules/digitalocean/etcd"

  base_domain             = "${var.tectonic_base_domain}"
  container_linux_channel = "${module.tectonic_container_linux_channel}"
  container_linux_version = "${module.tectonic_container_linux_version}"
  cluster_name            = "${var.tectonic_cluster_name}"
  container_image         = "${var.tectonic_container_images["etcd"]}"
  droplet_count           = "${var.tectonic_etcd_count > 0 ? var.tectonic_etcd_count : 3}"
  droplet_size            = "${var.tectonic_do_etcd_droplet_size}"
  droplet_region          = "${var.tectonic_do_droplet_region}"

  extra_tags              = "${var.tectonic_do_extra_tags}"
  ssh_keys                = "${var.tectonic_do_ssh_keys}"
  swap_size               = "${var.tectonic_do_etcd_swap}"
  tls_enabled             = "${var.tectonic_etcd_tls_enabled}"
  tls_zip                 = "${module.etcd_certs.etcd_tls_zip}"
}

module "ignition_masters" {
  source = "../../modules/ignition"

  base_domain               = "${var.tectonic_base_domain}"
  bootstrap_upgrade_cl      = "${var.tectonic_bootstrap_upgrade_cl}"
  cluster_name              = "${var.tectonic_cluster_name}"
  container_images          = "${var.tectonic_container_images}"
  etcd_advertise_name_list  = "${data.template_file.etcd_hostname_list.*.rendered}"
  etcd_count                = "${length(data.template_file.etcd_hostname_list.*.id)}"
  etcd_initial_cluster_list = "${data.template_file.etcd_hostname_list.*.rendered}"
  etcd_tls_enabled          = "${var.tectonic_etcd_tls_enabled}"
  image_re                  = "${var.tectonic_image_re}"
  kube_dns_service_ip       = "${module.bootkube.kube_dns_service_ip}"
  kubelet_cni_bin_dir       = "${var.tectonic_networking == "calico" || var.tectonic_networking == "canal" ? "/var/lib/cni/bin" : "" }"
  kubelet_node_label        = "node-role.kubernetes.io/master"
  kubelet_node_taints       = "node-role.kubernetes.io/master=:NoSchedule"
  swap_size                 = "${var.tectonic_do_master_swap}"
  tectonic_vanilla_k8s      = "${var.tectonic_vanilla_k8s}"
}

module "masters" {
  source = "../../modules/digitalocean/master"

  base_domain             = "${var.tectonic_base_domain}"
  container_linux_channel = "${module.tectonic_container_linux_channel}"
  container_linux_version = "${module.tectonic_container_linux_version}"
  cluster_name            = "${var.tectonic_cluster_name}"
  container_images        = "${var.tectonic_container_images}"
  droplet_size            = "${var.tectonic_do_master_droplet_size}"
  droplet_region          = "${var.tectonic_do_droplet_region}"
  extra_tags              = "${var.tectonic_do_extra_tags}"
  ssh_keys                = "${var.tectonic_do_ssh_keys}"

  #user_data = "${module.ignition.ignition_config.main.rendered}"

  ign_bootkube_path_unit_id         = "${module.bootkube.systemd_path_unit_id}"
  ign_bootkube_service_id           = "${module.bootkube.systemd_service_id}"
  ign_docker_dropin_id              = "${module.ignition_masters.docker_dropin_id}"
  ign_init_assets_service_id        = "${module.ignition_masters.init_assets_service_id}"
  ign_installer_kubelet_env_id      = "${module.ignition_masters.installer_kubelet_env_id}"
  ign_k8s_node_bootstrap_service_id = "${module.ignition_masters.k8s_node_bootstrap_service_id}"
  ign_kubelet_service_id            = "${module.ignition_masters.kubelet_service_id}"
  ign_locksmithd_service_id         = "${module.ignition_masters.locksmithd_service_id}"
  ign_max_user_watches_id           = "${module.ignition_masters.max_user_watches_id}"
  ign_tectonic_path_unit_id         = "${var.tectonic_vanilla_k8s ? "" : module.tectonic.systemd_path_unit_id}"
  ign_tectonic_service_id           = "${module.tectonic.systemd_service_id}"
  image_re                          = "${var.tectonic_image_re}"
}

module "ignition_workers" {
  source = "../../modules/ignition"

  bootstrap_upgrade_cl = "${var.tectonic_bootstrap_upgrade_cl}"
  container_images     = "${var.tectonic_container_images}"
  image_re             = "${var.tectonic_image_re}"
  kube_dns_service_ip  = "${module.bootkube.kube_dns_service_ip}"
  kubelet_cni_bin_dir  = "${var.tectonic_networking == "calico" || var.tectonic_networking == "canal" ? "/var/lib/cni/bin" : "" }"
  kubelet_node_label   = "node-role.kubernetes.io/node"
  kubelet_node_taints  = ""
  tectonic_vanilla_k8s = "${var.tectonic_vanilla_k8s}"
  swap_size            = "${var.tectonic_do_worker_swap}"
}

module "workers" {
  source = "../../modules/digitalocean/worker"

  base_domain             = "${var.tectonic_base_domain}"
  container_linux_channel = "${module.tectonic_container_linux_channel}"
  container_linux_version = "${module.tectonic_container_linux_version}"
  cluster_name            = "${var.tectonic_cluster_name}"
  droplet_count           = "${var.tectonic_worker_count}"
  droplet_size            = "${var.tectonic_do_worker_droplet_size}"
  droplet_region          = "${var.tectonic_do_droplet_region}"
  extra_tags              = "${var.tectonic_do_extra_tags}"
  ssh_keys                = "${var.tectonic_do_ssh_keys}"

  ign_docker_dropin_id              = "${module.ignition_workers.docker_dropin_id}"
  ign_installer_kubelet_env_id      = "${module.ignition_workers.installer_kubelet_env_id}"
  ign_k8s_node_bootstrap_service_id = "${module.ignition_workers.k8s_node_bootstrap_service_id}"
  ign_kubelet_service_id            = "${module.ignition_workers.kubelet_service_id}"
  ign_locksmithd_service_id         = "${module.ignition_masters.locksmithd_service_id}"
  ign_max_user_watches_id           = "${module.ignition_workers.max_user_watches_id}"
}
