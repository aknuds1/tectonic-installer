data "ignition_config" "etcd" {
  count = "${var.droplet_count}"

  systemd = [
    "${data.ignition_systemd_unit.locksmithd.id}",
    "${data.ignition_systemd_unit.etcd3.*.id[count.index]}",
  ]

  files = [
    "${data.ignition_file.node_hostname.*.id[count.index]}",
  ]
}

data "ignition_file" "node_hostname" {
  count = "${var.droplet_count}"
  path = "/etc/hostname"
  mode = 0644
  filesystem = "root"

  content {
    content = "${var.cluster_name}-etcd-${count.index}.${var.base_domain}"
  }
}

data "ignition_systemd_unit" "locksmithd" {
  count = 1
  name = "locksmithd.service"
  enable = true

  dropin = [
    {
      name = "40-etcd-lock.conf"
      content = "[Service]\nEnvironment=REBOOT_STRATEGY=etcd-lock\n"
    },
  ]
}

data "template_file" "etcd-cluster" {
  template = "${file("${path.module}/resources/etcd-cluster.tpl")}"
  count = "${var.droplet_count}"
  vars = {
    etcd-name = "${var.cluster_name}-etcd-${count.index}" 
    etcd-address = "${var.cluster_name}-etcd-${count.index}.${var.base_domain}"
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
ExecStart=
ExecStart=/usr/lib/coreos/etcd-wrapper \
  --name=${var.cluster_name}-etcd-${count.index} \
  --advertise-client-urls=http://${var.cluster_name}-etcd-${count.index}.${var.base_domain}:2379 \
  --initial-advertise-peer-urls=http://${var.cluster_name}-etcd-${count.index}.${var.base_domain}:2380 \
  --listen-client-urls=http://0.0.0.0:2379 \
  --listen-peer-urls=http://0.0.0.0:2380 \
  --initial-cluster="${join("," , data.template_file.etcd-cluster.*.rendered)}" 
EOF
    },
  ]
}
