output "node_addresses" {
  value = ["${digitalocean_droplet.worker_node.*.ipv4_address}"]
}
