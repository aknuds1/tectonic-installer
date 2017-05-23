output "endpoints" {
  value = ["${digitalocean_domain.etcd_nodes.*.id}"]
}
