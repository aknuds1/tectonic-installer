output "endpoints" {
  value = ["${digitalocean_domain.etc_nodes.*.id}"]
}
