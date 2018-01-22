variable "tectonic_do_config_version" {
  description = <<EOF
(internal) This declares the version of the DigitalOcean configuration variables.
It has no impact on generated assets but declares the version contract of the configuration.
EOF

  default = "1.0"
}

variable "tectonic_do_token" {
  type        = "string"
  description = "(REQUIRED) DigitalOcean API token."
}

variable "tectonic_do_ssh_keys" {
  type        = "list"
  description = "A list of DigitalOcean SSH IDs to enable. Retrieve via `doctl compute ssh-key list` or `tugboat keys`. Example: `[\"123456\", \"987654\"]`"
}

variable "tectonic_do_droplet_region" {
  type        = "string"
  default     = "nyc3"
  description = "Slug of region to create cluster in. See: `doctl compute region list` or `tugboat regions` for available region slugs.  Default: `nyc3`."
}

variable "tectonic_do_master_droplet_size" {
  type        = "string"
  default     = "1gb"
  description = "Instance slug to use for the master node(s). See `doctl compute size list`  or `tugboat sizes` for available slugs. Default: `1gb`."
}

variable "tectonic_do_worker_droplet_size" {
  type        = "string"
  default     = "512mb"
  description = "Instance slug to use for the worker node(s). See `doctl compute size list` or `tugboat sizes` for available slugs.  Default: `512mb`."
}

variable "tectonic_do_etcd_droplet_size" {
  type        = "string"
  default     = "512mb"
  description = "Instance slug to use for the worker node(s). See `doctl compute size list` or `tugboat sizes` for available slugs.  Default: `512mb`."
}

variable "tectonic_do_extra_tags" {
  type    = "list"
  default = []
}

variable "tectonic_do_spaces_access_key_id" {
  type        = "string"
  description = "Spaces access key ID"
}

variable "tectonic_do_spaces_secret_access_key" {
  type        = "string"
  description = "Spaces secret access key"
}

variable "tectonic_do_spaces_region" {
  type        = "string"
  default     = "nyc3"
  description = "Spaces region"
}
