output "api_external_fqdn" {
  value = "${aws_route53_record.api-external.name}"
}
