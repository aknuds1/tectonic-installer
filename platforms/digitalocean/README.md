# Tectonic Installer for DigitalOcean

## etcd
We create an etcd cluster with a default of 3 droplets (controlled by `tectonic_etcd_count`).
A domain, etcd.<cluster_domain> is created for the etcd cluster, for purely technical reasons
(avoiding a dependency cycle in Terraform). Every etcd node receives a DNS address
etcd-<number>.etcd.<cluster_domain>.
