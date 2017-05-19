data "ignition_systemd_unit" "sshguard" {
  name = "sshguard.service"
  enable = true
  content = "${file("${path.module}/resources/services/sshguard.service")}"
}
