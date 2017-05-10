variable "tectonic_do_config_version" {
  description = <<EOF
(internal) This declares the version of the DigitalOcean configuration variables.
It has no impact on generated assets but declares the version contract of the configuration.
EOF

  default = "1.0"
}

variable "tectonic_do_token" {
  type = "string"
  description = "DigitalOcean API token."
}

variable "tectonic_do_ssh_keys" {
  type = "list"
  description = "A list of SSH IDs to enable."
}

variable "tectonic_do_droplet_image" {
  type = "string"
  description = "Droplet image."
  default = "coreos-stable"
}

variable "tectonic_do_master_droplet_size" {
  type = "string"
  description = "Instance size for the master node(s). Example: `512mb`."
  default = "512mb"
}

variable "tectonic_do_droplet_region" {
  type = "string"
  description = "Region for the droplets."
  default = "nyc1"
}

variable "tectonic_do_etcd_droplet_size" {
  type = "string"
  description = "Droplet size for the etcd node(s). Example: `512mb`."
  default = "512mb"
}

variable "tectonic_do_extra_tags" {
  type = "list"
  default = []
}

variable "tectonic_aws_region" {
  type = "string"
  default = "eu-west-1"
  description = "The target AWS region."
}

variable "tectonic_aws_profile" {
  type = "string"
  default = "default"
  description = "AWS profile name as set in the shared credentials file."
}
