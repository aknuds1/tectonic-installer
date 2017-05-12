output "endpoints" {
  value = ["${digitalocean_domain.etc_a_nodes.*.id}"]
}
