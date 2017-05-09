resource "aws_route53_zone" "tectonic-int" {
  name = "${var.tectonic_base_domain}"
  force_destroy = true
  tags = "${map(
    "Name", "${var.tectonic_cluster_name}_tectonic_int_zone",
    "KubernetesCluster", "${var.tectonic_cluster_name}"
  )}"
}
