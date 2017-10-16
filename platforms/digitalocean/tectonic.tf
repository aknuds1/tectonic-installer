data "template_file" "etcd_hostname_list" {
  count    = "${var.tectonic_experimental ? 0 : max(var.tectonic_etcd_count, 1)}"
  template = "${var.tectonic_cluster_name}-etcd-${count.index}.${var.tectonic_base_domain}"
}

module "kube_certs" {
  source = "../../modules/tls/kube/self-signed"

  ca_cert_pem        = "${var.tectonic_ca_cert}"
  ca_key_alg         = "${var.tectonic_ca_key_alg}"
  ca_key_pem         = "${var.tectonic_ca_key}"
  kube_apiserver_url = "https://${module.masters.cluster_fqdn}:443"
  service_cidr       = "${var.tectonic_service_cidr}"
}

module "etcd_certs" {
  source = "../../modules/tls/etcd"

  etcd_ca_cert_path     = "${var.tectonic_etcd_ca_cert_path}"
  etcd_cert_dns_names   = "${data.template_file.etcd_hostname_list.*.rendered}"
  etcd_client_cert_path = "${var.tectonic_etcd_client_cert_path}"
  etcd_client_key_path  = "${var.tectonic_etcd_client_key_path}"
  self_signed           = "${var.tectonic_experimental || var.tectonic_etcd_tls_enabled}"
  service_cidr          = "${var.tectonic_service_cidr}"
}

module "ingress_certs" {
  source = "../../modules/tls/ingress/self-signed"

  base_address = "${module.masters.console_fqdn}"
  ca_cert_pem  = "${module.kube_certs.ca_cert_pem}"
  ca_key_alg   = "${module.kube_certs.ca_key_alg}"
  ca_key_pem   = "${module.kube_certs.ca_key_pem}"
}

module "identity_certs" {
  source = "../../modules/tls/identity/self-signed"

  ca_cert_pem = "${module.kube_certs.ca_cert_pem}"
  ca_key_alg  = "${module.kube_certs.ca_key_alg}"
  ca_key_pem  = "${module.kube_certs.ca_key_pem}"
}

module "bootkube" {
  source         = "../../modules/bootkube"
  cloud_provider = "digitalocean"

  cluster_name = "${var.tectonic_cluster_name}"

  ## TODO Add private endpoints
  kube_apiserver_url = "https://${module.masters.cluster_fqdn}:443"
  oidc_issuer_url    = "https://${module.masters.console_fqdn}:443/identity"

  # Platform-independent variables wiring, do not modify.
  container_images = "${var.tectonic_container_images}"
  versions         = "${var.tectonic_versions}"

  service_cidr = "${var.tectonic_service_cidr}"
  cluster_cidr = "${var.tectonic_cluster_cidr}"

  advertise_address = "0.0.0.0"
  anonymous_auth    = "false"

  oidc_username_claim = "email"
  oidc_groups_claim   = "groups"
  oidc_client_id      = "tectonic-kubectl"
  oidc_ca_cert        = "${module.ingress_certs.ca_cert_pem}"

  apiserver_cert_pem   = "${module.kube_certs.apiserver_cert_pem}"
  apiserver_key_pem    = "${module.kube_certs.apiserver_key_pem}"
  etcd_ca_cert_pem     = "${module.etcd_certs.etcd_ca_crt_pem}"
  etcd_client_cert_pem = "${module.etcd_certs.etcd_client_crt_pem}"
  etcd_client_key_pem  = "${module.etcd_certs.etcd_client_key_pem}"
  etcd_peer_cert_pem   = "${module.etcd_certs.etcd_peer_crt_pem}"
  etcd_peer_key_pem    = "${module.etcd_certs.etcd_peer_key_pem}"
  etcd_server_cert_pem = "${module.etcd_certs.etcd_server_crt_pem}"
  etcd_server_key_pem  = "${module.etcd_certs.etcd_server_key_pem}"
  kube_ca_cert_pem     = "${module.kube_certs.ca_cert_pem}"
  kubelet_cert_pem     = "${module.kube_certs.kubelet_cert_pem}"
  kubelet_key_pem      = "${module.kube_certs.kubelet_key_pem}"

  etcd_endpoints       = "${module.etcd.endpoints}"
  experimental_enabled = "${var.tectonic_experimental}"
  master_count         = "${var.tectonic_master_count}"

  cloud_config_path = ""
}

module "tectonic" {
  source   = "../../modules/tectonic"
  platform = "digitalocean"

  cluster_name       = "${var.tectonic_cluster_name}"
  ## TODO Add private endpoints
  base_address       = "${module.masters.console_fqdn}"
  ## TODO Add private endpoints
  kube_apiserver_url = "https://${module.masters.cluster_fqdn}:443"
  service_cidr       = "${var.tectonic_service_cidr}"

  # Platform-independent variables wiring, do not modify.
  container_images      = "${var.tectonic_container_images}"
  container_base_images = "${var.tectonic_container_base_images}"
  versions              = "${var.tectonic_versions}"
  license_path          = "${var.tectonic_vanilla_k8s ? "/dev/null" : pathexpand(var.tectonic_license_path)}"
  pull_secret_path      = "${var.tectonic_vanilla_k8s ? "/dev/null" : pathexpand(var.tectonic_pull_secret_path)}"
  admin_email           = "${var.tectonic_admin_email}"
  admin_password        = "${var.tectonic_admin_password}"
  update_channel        = "${var.tectonic_update_channel}"
  update_app_id         = "${var.tectonic_update_app_id}"
  update_server         = "${var.tectonic_update_server}"
  ca_generated          = "${var.tectonic_ca_cert == "" ? false : true}"
  ca_cert               = "${module.kube_certs.ca_cert_pem}"

  ingress_ca_cert_pem = "${module.ingress_certs.ca_cert_pem}"
  ingress_cert_pem    = "${module.ingress_certs.cert_pem}"
  ingress_key_pem     = "${module.ingress_certs.key_pem}"

  identity_client_cert_pem = "${module.identity_certs.client_cert_pem}"
  identity_client_key_pem  = "${module.identity_certs.client_key_pem}"
  identity_server_cert_pem = "${module.identity_certs.server_cert_pem}"
  identity_server_key_pem  = "${module.identity_certs.server_key_pem}"

  console_client_id = "tectonic-console"
  kubectl_client_id = "tectonic-kubectl"
  ingress_kind      = "NodePort"
  experimental      = "${var.tectonic_experimental}"
  master_count      = "${var.tectonic_master_count}"
  stats_url         = "${var.tectonic_stats_url}"

  image_re = "${var.tectonic_image_re}"
}

module "flannel_vxlan" {
  source = "../../modules/net/flannel-vxlan"

  cluster_cidr      = "${var.tectonic_cluster_cidr}"
  enabled           = "${var.tectonic_networking == "flannel"}"
  container_images = "${var.tectonic_container_images}"
  #flannel_image     = "${var.tectonic_container_images["flannel"]}"
  #flannel_cni_image = "${var.tectonic_container_images["flannel_cni"]}"
}

module "calico" {
  source = "../../modules/net/calico"

  #kube_apiserver_url = "https://${module.masters.cluster_fqdn}:443"
  container_images   = "${var.tectonic_container_images}"
  #calico_image       = "${var.tectonic_container_images["calico"]}"
  #calico_cni_image   = "${var.tectonic_container_images["calico_cni"]}"
  cluster_cidr       = "${var.tectonic_cluster_cidr}"
  enabled            = "${var.tectonic_networking == "calico"}"
}

module "canal" {
  source = "../../modules/net/canal"

  container_images = "${var.tectonic_container_images}"
  cluster_cidr     = "${var.tectonic_cluster_cidr}"
  enabled          = "${var.tectonic_networking == "canal"}"
}

data "archive_file" "assets" {
  type       = "zip"
  source_dir = "./generated/"

  # Because the archive_file provider is a data source, depends_on can't be
  # used to guarantee that the tectonic/bootkube modules have generated
  # all the assets on disk before trying to archive them. Instead, we use their
  # ID outputs, that are only computed once the assets have actually been
  # written to disk. We re-hash the IDs (or dedicated module outputs, like module.bootkube.content_hash)
  # to make the filename shorter, since there is no security nor collision risk anyways.
  #
  # Additionally, data sources do not support managing any lifecycle whatsoever,
  # and therefore, the archive is never deleted. To avoid cluttering the module
  # folder, we write it in the Terraform managed hidden folder `.terraform`.
  output_path = "./.terraform/generated_${sha1("${module.etcd_certs.id} ${module.tectonic.id} ${module.bootkube.id} ${module.flannel_vxlan.id} ${module.calico.id} ${module.canal.id}")}.zip"
}

# Copy kubeconfig to master nodes
resource "null_resource" "master_nodes" {
  count = 1

  # Re-provision on changes to masters
  triggers {
    master_address = "${element(module.masters.node_addresses, count.index)}"
  }

  connection {
    type        = "ssh"
    host        = "${element(module.masters.node_addresses, count.index)}"
    user        = "core"
    private_key = "${file("${var.tectonic_do_ssh_key_path}")}"
    timeout     = "1m"
  }

  provisioner "file" {
    content     = "${module.bootkube.kubeconfig}"
    destination = "$HOME/kubeconfig"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv $HOME/kubeconfig /etc/kubernetes/",
    ]
  }
}

# Copy assets to first master node
resource "null_resource" "first_master" {
  # Re-provision on changes to first master node
  triggers {
    node_address = "${module.masters.first_node_address}"
  }

  connection {
    type        = "ssh"
    host        = "${module.masters.first_node_address}"
    user        = "core"
    private_key = "${file("${var.tectonic_do_ssh_key_path}")}"
    timeout     = "1m"
  }

  provisioner "file" {
    source      = "${data.archive_file.assets.output_path}"
    destination = "$HOME/tectonic.zip"
  }

  provisioner "file" {
    source      = "${path.root}/resources/bootstrap-first-master.sh"
    destination = "$HOME/bootstrap-first-master.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x $HOME/bootstrap-first-master.sh",
      "$HOME/bootstrap-first-master.sh ${var.tectonic_vanilla_k8s ? "" : "--enable-tectonic"}",
      "rm $HOME/bootstrap-first-master.sh",
    ]
  }
}

# Copy kubeconfig to worker nodes
resource "null_resource" "worker_nodes" {
  count = "${var.tectonic_worker_count}"

  # Re-provision on changes to workers
  triggers {
    node_address = "${element(module.workers.node_addresses, count.index)}"
  }

  connection {
    type        = "ssh"
    host        = "${element(module.workers.node_addresses, count.index)}"
    user        = "core"
    private_key = "${file("${var.tectonic_do_ssh_key_path}")}"
    timeout     = "1m"
  }

  provisioner "file" {
    content     = "${module.bootkube.kubeconfig}"
    destination = "$HOME/kubeconfig"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv $HOME/kubeconfig /etc/kubernetes/",
    ]
  }
}