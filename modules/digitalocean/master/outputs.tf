output "api_external_fqdn" {
  value = ["${digitalocean_domain.api-external.*.id}"]
}
