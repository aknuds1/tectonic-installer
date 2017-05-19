output "service_id" {
  value = "${data.ignition_systemd_unit.swap.id}"
}
