data "ignition_systemd_unit" "sshguard" {
  name     = "sshguard.service"
  enabled  = true
  content  = "${file("${path.module}/resources/services/sshguard.service")}"
}
