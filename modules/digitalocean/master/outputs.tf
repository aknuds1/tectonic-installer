# output "api_fqdn" {
#   value = "${digitalocean_domain.api.id}"
# }

output "console_fqdn" {
  value = "${digitalocean_domain.console.id}"
}

output "first_node_address" {
  value = "${digitalocean_droplet.master_node.*.ipv4_address[0]}"
}

output "node_addresses" {
  value = ["${digitalocean_droplet.master_node.*.ipv4_address}"]
}
