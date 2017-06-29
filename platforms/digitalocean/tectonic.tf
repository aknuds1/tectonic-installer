module "bootkube" {
  source = "../../modules/bootkube"
  
  cloud_provider = ""
  kube_apiserver_url = "https://${module.masters.cluster_fqdn}:443"
  oidc_issuer_url = "https://${digitalocean_loadbalancer.tectonic-console.ip}:443/identity"
  # Platform-independent variables wiring, do not modify.
  container_images = "${var.tectonic_container_images}"
  ca_cert = "${var.tectonic_ca_cert}"
  ca_key = "${var.tectonic_ca_key}"
  ca_key_alg = "${var.tectonic_ca_key_alg}"
  service_cidr = "${var.tectonic_service_cidr}"
  cluster_cidr = "${var.tectonic_cluster_cidr}"
  advertise_address = "0.0.0.0"
  anonymous_auth = "false"
  oidc_username_claim = "email"
  oidc_groups_claim = "groups"
  oidc_client_id = "tectonic-kubectl"
  etcd_endpoints = ["${module.etcd.endpoints}"]
  etcd_ca_cert = "${var.tectonic_etcd_ca_cert_path}"
  etcd_client_cert = "${var.tectonic_etcd_client_cert_path}"
  etcd_client_key = "${var.tectonic_etcd_client_key_path}"
  experimental_enabled = "${var.tectonic_experimental}"
  versions = "${var.tectonic_versions}"
}

module "tectonic" {
  source = "../../modules/tectonic"

  platform = "digitalocean"
  base_address = "${var.tectonic_vanilla_k8s ? "" : digitalocean_loadbalancer.tectonic-console.ip}"
  kube_apiserver_url = "https://${module.masters.cluster_fqdn}:443"
  # Platform-independent variables wiring, do not modify.
  container_images = "${var.tectonic_container_images}"
  versions = "${var.tectonic_versions}"
  license_path = "${pathexpand(var.tectonic_license_path)}"
  pull_secret_path = "${pathexpand(var.tectonic_pull_secret_path)}"
  admin_email = "${var.tectonic_admin_email}"
  admin_password_hash = "${var.tectonic_admin_password_hash}"
  update_channel = "${var.tectonic_update_channel}"
  update_app_id = "${var.tectonic_update_app_id}"
  update_server = "${var.tectonic_update_server}"
  ca_generated = "${module.bootkube.ca_cert == "" ? false : true}"
  ca_cert = "${module.bootkube.ca_cert}"
  ca_key_alg = "${module.bootkube.ca_key_alg}"
  ca_key = "${module.bootkube.ca_key}"
  console_client_id = "tectonic-console"
  kubectl_client_id = "tectonic-kubectl"
  ingress_kind = "NodePort"
  experimental = "${var.tectonic_experimental}"
  master_count = 1
}

data "archive_file" "assets" {
  type = "zip"
  source_dir = "${path.cwd}/generated/"
  # Because the archive_file provider is a data source, depends_on can't be
  # used to guarantee that the tectonic/bootkube modules have generated
  # all the assets on disk before trying to archive them. Instead, we use their
  # ID outputs, that are only computed once the assets have actually been
  # written to disk. We re-hash the IDs (or dedicated module outputs, like module.bootkube.content_hash)
  # to make the filename shorter, since there is no security nor collision risk anyways.
  #
  # Additionally, data sources do not support managing any lifecycle whatsoever,
  # and therefore, the archive is never deleted. To avoid cluttering the module
  # folder, we write it in the TerraForm managed hidden folder `.terraform`.
  output_path = "${path.cwd}/.terraform/generated_${sha1("${module.tectonic.id} ${module.bootkube.id}")}.zip"
}

# Copy kubeconfig to master nodes
resource "null_resource" "master_nodes" {
  count = 1
  # Re-provision on changes to masters
  triggers {
    master_address = "${element(module.masters.node_addresses, count.index)}",
  }

  connection {
    type = "ssh"
    host = "${element(module.masters.node_addresses, count.index)}"
    user = "core"
    private_key = "${file("${var.tectonic_do_ssh_key_path}")}"
    timeout = "1m"
  }
  
  provisioner "file" {
    content = "${module.bootkube.kubeconfig}"
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
    type = "ssh"
    host = "${module.masters.first_node_address}"
    user = "core"
    private_key = "${file("${var.tectonic_do_ssh_key_path}")}"
    timeout = "1m"
  }
  
  provisioner "file" {
    source = "${data.archive_file.assets.output_path}"
    destination = "$HOME/tectonic.zip"
  }

  provisioner "file" {
    source = "${path.root}/resources/bootstrap-first-master.sh"
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
    node_address = "${element(module.workers.node_addresses, count.index)}",
  }

  connection {
    type = "ssh"
    host = "${element(module.workers.node_addresses, count.index)}"
    user = "core"
    private_key = "${file("${var.tectonic_do_ssh_key_path}")}"
    timeout = "1m"
  }
  
  provisioner "file" {
    content = "${module.bootkube.kubeconfig}"
    destination = "$HOME/kubeconfig"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv $HOME/kubeconfig /etc/kubernetes/",
    ]
  }
}

resource digitalocean_loadbalancer "tectonic-console" {
  name = "tectonic-console"
  region = "${var.tectonic_do_droplet_region}"
  droplet_ids = ["${module.masters.node_ids}"]
  
  forwarding_rule {
    entry_port = 80
    entry_protocol = "http"
    target_port = 32001
    target_protocol = "http"
  }
  
  forwarding_rule {
    entry_port = 443
    entry_protocol = "https"
    target_port = 32000
    target_protocol = "https"
    tls_passthrough = true
  }
  
  healthcheck {
    port = 32002
    protocol = "http"
    path = "/healthz"
    response_timeout_seconds = 3
    check_interval_seconds = 5
  }
}
