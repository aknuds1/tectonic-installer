data "ignition_config" "etcd" {
  count = "${var.droplet_count}"

  systemd = [
    "${data.ignition_systemd_unit.locksmithd.*.id[count.index]}",
    "${data.ignition_systemd_unit.etcd3.*.id[count.index]}",
    "${module.swap.service_id}",
    "${module.sshguard.service_id}",
  ]

  files = [
    "${data.ignition_file.node_hostname.*.id[count.index]}",
    "${data.ignition_file.etcd_ca.id}",
    "${data.ignition_file.etcd_client_crt.id}",
    "${data.ignition_file.etcd_client_key.id}",
    "${data.ignition_file.etcd_peer_crt.id}",
    "${data.ignition_file.etcd_peer_key.id}",
  ]
}

data "ignition_file" "node_hostname" {
  count = "${var.droplet_count}"
  path = "/etc/hostname"
  mode = 0644
  filesystem = "root"

  content {
    content = "etcd-${count.index}.etcd.${var.cluster_domain}"
  }
}

data "ignition_file" "etcd_ca" {
  path = "/etc/ssl/etcd/ca.crt"
  mode = 0644
  uid = 232
  gid = 232
  filesystem = "root"

  content {
    content = "${var.tls_ca_crt_pem}"
  }
}

data "ignition_file" "etcd_client_key" {
  path = "/etc/ssl/etcd/client.key"
  mode = 0400
  uid = 232
  gid = 232
  filesystem = "root"

  content {
    content = "${var.tls_client_key_pem}"
  }
}

data "ignition_file" "etcd_client_crt" {
  path = "/etc/ssl/etcd/client.crt"
  mode = 0400
  uid = 232
  gid = 232
  filesystem = "root"

  content {
    content = "${var.tls_client_crt_pem}"
  }
}

data "ignition_file" "etcd_peer_key" {
  path = "/etc/ssl/etcd/peer.key"
  mode = 0400
  uid = 232
  gid = 232
  filesystem = "root"

  content {
    content = "${var.tls_peer_key_pem}"
  }
}

data "ignition_file" "etcd_peer_crt" {
  path = "/etc/ssl/etcd/peer.crt"
  mode = 0400
  uid = 232
  gid = 232
  filesystem = "root"

  content {
    content = "${var.tls_peer_crt_pem}"
  }
}

data "ignition_systemd_unit" "locksmithd" {
  count = "${var.droplet_count}"
  name = "locksmithd.service"
  enable = true
  dropin = [
    {
      name = "40-etcd-lock.conf"
      content = <<EOF
[Service]
Environment=REBOOT_STRATEGY=etcd-lock
${var.tls_enabled ? "Environment=\"LOCKSMITHD_ETCD_CAFILE=/etc/ssl/etcd/ca.crt\"" : ""}
${var.tls_enabled ? "Environment=\"LOCKSMITHD_ETCD_KEYFILE=/etc/ssl/etcd/client.key\"" : ""}
${var.tls_enabled ? "Environment=\"LOCKSMITHD_ETCD_CERTFILE=/etc/ssl/etcd/client.crt\"" : ""}
Environment="LOCKSMITHD_ENDPOINT=${var.tls_enabled ? "https" : "http"}://etcd-${count.index}.etcd.${var.cluster_domain}:2379"
EOF
    },
  ]
}

data "template_file" "etcd-cluster" {
  template = "${file("${path.module}/resources/etcd-cluster.tpl")}"
  count = "${var.droplet_count}"
  vars = {
    etcd-name = "${var.cluster_name}-etcd-${count.index}"
    etcd-address = "etcd-${count.index}.etcd.${var.cluster_domain}"
  }
}

data "ignition_systemd_unit" "etcd3" {
  count = "${var.droplet_count}"
  name = "etcd-member.service"
  enable = true
  dropin = [
    {
      name = "40-etcd-cluster.conf"
      content = <<EOF
[Service]
Environment="ETCD_IMAGE=${var.container_image}"
Environment="RKT_RUN_ARGS=--volume etcd-ssl,kind=host,source=/etc/ssl/etcd \
  --mount volume=etcd-ssl,target=/etc/ssl/etcd"
ExecStart=
ExecStart=/usr/lib/coreos/etcd-wrapper \
  --name=${var.cluster_name}-etcd-${count.index} \
  --advertise-client-urls=${var.tls_enabled ? "https" : "http"}://etcd-${count.index}.etcd.${var.cluster_domain}:2379 \
  ${var.tls_enabled
      ? "--cert-file=/etc/ssl/etcd/client.crt --key-file=/etc/ssl/etcd/client.key --peer-cert-file=/etc/ssl/etcd/peer.crt --peer-key-file=/etc/ssl/etcd/peer.key --peer-trusted-ca-file=/etc/ssl/etcd/ca.crt -peer-client-cert-auth=true"
      : ""} \
  --initial-advertise-peer-urls=${var.tls_enabled ? "https" : "http"}://etcd-${count.index}.etcd.${var.cluster_domain}:2380 \
  --listen-client-urls=${var.tls_enabled ? "https" : "http"}://0.0.0.0:2379 \
  --listen-peer-urls=${var.tls_enabled ? "https" : "http"}://0.0.0.0:2380 \
  --initial-cluster="${join("," , data.template_file.etcd-cluster.*.rendered)}"
EOF
    },
  ]
}

module "swap" {
  source = "../swap"
  
  swap_size = "${var.swap_size}"
}

module "sshguard" {
  source = "../../sshguard"
}
