data "ignition_config" "etcd" {
  count = "${var.droplet_count}"

  systemd = [
    "${data.ignition_systemd_unit.locksmithd.*.id[count.index]}",
    "${data.ignition_systemd_unit.etcd3.*.id[count.index]}",
    "${data.ignition_systemd_unit.etcd_unzip_tls.id}",
    "${module.swap.service_id}",
    "${module.sshguard.service_id}",
  ]

  files = [
    "${data.ignition_file.node_hostname.*.id[count.index]}",
    "${data.ignition_file.etcd_tls_zip.id}",
  ]
}

data "ignition_file" "node_hostname" {
  count      = "${var.droplet_count}"
  path       = "/etc/hostname"
  mode       = 0644
  filesystem = "root"

  content {
    content = "${var.cluster_name}-etcd-${count.index}.${var.base_domain}"
  }
}

data "ignition_file" "etcd_tls_zip" {
  path       = "/etc/ssl/etcd/tls.zip"
  mode       = 0400
  uid        = 0
  gid        = 0
  filesystem = "root"

  content {
    mime    = "application/octet-stream"
    content = "${var.tls_zip}"
  }
}

data "ignition_systemd_unit" "etcd_unzip_tls" {
  name   = "etcd-unzip-tls.service"
  enable = true

  content = <<EOF
[Unit]
ConditionPathExists=!/etc/ssl/etcd/ca.crt
[Service]
Type=oneshot
WorkingDirectory=/etc/ssl/etcd
ExecStart=/usr/bin/bash -c 'unzip /etc/ssl/etcd/tls.zip && \
chown etcd:etcd /etc/ssl/etcd/peer.* && \
chown etcd:etcd /etc/ssl/etcd/client.* && \
chown etcd:etcd /etc/ssl/etcd/server.* && \
chmod 0400 /etc/ssl/etcd/peer.* /etc/ssl/etcd/server.* /etc/ssl/etcd/client.*'
[Install]
WantedBy=multi-user.target
RequiredBy=etcd-member.service locksmithd.service
EOF
}

data "ignition_systemd_unit" "locksmithd" {
  count  = "${var.droplet_count}"
  name   = "locksmithd.service"
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
Environment="LOCKSMITHD_ENDPOINT=${var.tls_enabled ? "https" : "http"}://${var.cluster_name}-etcd-${count.index}.${var.base_domain}:2379"
EOF
    },
  ]
}

data "template_file" "etcd-cluster" {
  template = "${file("${path.module}/resources/etcd-cluster.tpl")}"
  count    = "${var.droplet_count}"

  vars = {
    etcd-name    = "${var.cluster_name}-etcd-${count.index}"
    etcd-address = "${var.cluster_name}-etcd-${count.index}.${var.base_domain}"
    tls-enabled  = "${var.tls_enabled}"
  }
}

data "ignition_systemd_unit" "etcd3" {
  count  = "${var.droplet_count}"
  name   = "etcd-member.service"
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
  --advertise-client-urls=${var.tls_enabled ? "https" : "http"}://${var.cluster_name}-etcd-${count.index}.${var.base_domain}:2379 \
  ${var.tls_enabled
      ? "--cert-file=/etc/ssl/etcd/server.crt --key-file=/etc/ssl/etcd/server.key --peer-cert-file=/etc/ssl/etcd/peer.crt --peer-key-file=/etc/ssl/etcd/peer.key --peer-trusted-ca-file=/etc/ssl/etcd/ca.crt -peer-client-cert-auth=true"
      : ""} \
  --initial-advertise-peer-urls=${var.tls_enabled ? "https" : "http"}://${var.cluster_name}-etcd-${count.index}.${var.base_domain}:2380 \
  --listen-client-urls=${var.tls_enabled ? "https" : "http"}://0.0.0.0:2379 \
  --listen-peer-urls=${var.tls_enabled ? "https" : "http"}://0.0.0.0:2380 \
  --initial-cluster="${join("," , data.template_file.etcd-cluster.*.rendered)}"
EOF
    },
  ]
}

module "swap" {
  source = "../../swap"

  swap_size = "${var.swap_size}"
}

module "sshguard" {
  source = "../../sshguard"
}
