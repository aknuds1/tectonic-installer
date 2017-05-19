data "template_file" "swap" {
  template = "${file("${path.module}/resources/services/swap.service.tpl")}"
  vars {
    swap_size = "${var.swap_size}"
  }
}

data "ignition_systemd_unit" "swap" {
  name = "swap.service"
  enable = "${var.swap_size != "" ? true : false}"
  content = "${data.template_file.swap.rendered}"
}
