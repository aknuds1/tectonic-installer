data "ignition_config" "etcd" {
  count = "${var.droplet_count}"

  systemd = [
    "${data.ignition_systemd_unit.locksmithd.*.id[count.index]}",
    "${var.ign_etcd_dropin_id_list[count.index]}",
  ]

  files = [
    "${compact(list(var.ign_profile_env_id, var.ign_systemd_default_env_id,))}",
    "${var.ign_etcd_crt_id_list}",
    "${data.ignition_file.node_hostname.*.id[count.index]}",
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

data "ignition_systemd_unit" "locksmithd" {
  count   = "${var.droplet_count}"
  name    = "locksmithd.service"
  enabled = true

  dropin = [
    {
      name = "40-etcd-lock.conf"

      content = <<EOF
[Service]
Environment=REBOOT_STRATEGY=etcd-lock
Environment="LOCKSMITHD_ETCD_CAFILE=/etc/ssl/etcd/ca.crt"
Environment="LOCKSMITHD_ETCD_KEYFILE=/etc/ssl/etcd/client.key"
Environment="LOCKSMITHD_ETCD_CERTFILE=/etc/ssl/etcd/client.crt"
Environment="LOCKSMITHD_ENDPOINT=https://${var.cluster_name}-etcd-${count.index}.${var.base_domain}:2380"
EOF
    },
  ]
}
