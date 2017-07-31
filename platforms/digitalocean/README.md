# Tectonic Installer for DigitalOcean
This is Tectonic Installer for the [DigitalOcean](http://digitalocean.com/) hosting platform.

## etcd
We create an etcd cluster with a default of 3 droplets (controlled by the variable
`tectonic_etcd_count`). A domain, etcd.<cluster_domain> is created for the etcd cluster,
for purely technical reasons (avoiding a dependency cycle in Terraform). Every etcd node
receives a DNS address etcd-<number>.etcd.<cluster_domain>.

### Testing
In order to test the etcd cluster, ssh into one of the etcd nodes and issue the following command 
(setting `$CLUSTER_NAME` and `$DOMAIN_NAME` correspondingly):
`sudo ETCDCTL_API=3 etcdctl --ca-file=/etc/ssl/etcd/ca.crt --cert-file=/etc/ssl/etcd/client.crt --key-file=/etc/ssl/etcd/client.key --endpoints=https://etcd-0.etcd.$CLUSTER_NAME.k8s.$DOMAIN_NAME:2379 cluster-health`.
This should report that the cluster is healthy.
