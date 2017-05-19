output "api_external_fqdn" {
  value = "${digitalocean_domain.api-external.*.id[0]}"
}

output "first_node_address" {
  value = "${digitalocean_droplet.master_node.*.ipv4_address[0]}"
}

output "node_addresses" {
  value = ["${digitalocean_droplet.master_node.*.ipv4_address}"]
}
