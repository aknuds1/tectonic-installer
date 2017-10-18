resource "digitalocean_droplet" "master_node" {
  count = "${var.master_count}"
  name      = "${var.cluster_name}-master-${count.index}"
  image     = "coreos-${var.container_linux_channel}"
  region    = "${var.droplet_region}"
  size      = "${var.droplet_size}"
  ssh_keys  = ["${var.ssh_keys}"]
  tags      = ["${var.extra_tags}"]
  user_data = "${data.ignition_config.main.rendered}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "digitalocean_loadbalancer" "console" {
  name        = "${var.cluster_name}-con"
  region      = "${var.droplet_region}"
  droplet_ids = ["${digitalocean_droplet.master_node.*.id}"]

  forwarding_rule {
    entry_port      = 80
    entry_protocol  = "tcp"
    target_port     = 32001
    target_protocol = "tcp"
  }

  forwarding_rule {
    entry_port      = 443
    entry_protocol  = "tcp"
    target_port     = 32000
    target_protocol = "tcp"
  }

  healthcheck {
    port                     = 32002
    protocol                 = "http"
    path                     = "/healthz"
    check_interval_seconds   = 5
    response_timeout_seconds = 3
    healthy_threshold        = 2
    unhealthy_threshold      = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "digitalocean_domain" "cluster" {
  name       = "${var.cluster_name}.${var.base_domain}"
  ip_address = "${digitalocean_droplet.master_node.*.ipv4_address[0]}"
}

resource "digitalocean_domain" "console" {
  name       = "console.${var.cluster_name}.${var.base_domain}"
  ip_address = "${digitalocean_loadbalancer.console.ip}"
}

resource "digitalocean_record" "master" {
  count  = "${var.master_count}"
  domain = "${digitalocean_domain.cluster.id}"
  type   = "A"
  name   = "${var.cluster_name}-master-${count.index}"
  value  = "${element(digitalocean_droplet.master_node.*.ipv4_address, count.index)}"
}
