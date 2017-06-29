output "cluster_fqdn" {
  value = "${digitalocean_domain.cluster.id}"
}

output "first_node_address" {
  value = "${digitalocean_droplet.master_node.*.ipv4_address[0]}"
}

output "node_addresses" {
  value = ["${digitalocean_droplet.master_node.*.ipv4_address}"]
}

output "node_ids" {
  value = ["${digitalocean_droplet.master_node.*.id}"]
}
