# Tectonic Installer for DigitalOcean
This is Tectonic Installer for the [DigitalOcean](http://digitalocean.com/) hosting platform.

## etcd
We create an etcd cluster with a default of 3 droplets (controlled by the variable
`tectonic_etcd_count`). A domain, etcd.<cluster-name> is created for the etcd cluster,
for purely technical reasons (avoiding a dependency cycle in Terraform). Every etcd node
receives a DNS address etcd-<number>.etcd.<cluster-name>.

### Testing
In order to test the etcd cluster, ssh into one of the etcd nodes and issue the following command
(setting `$CLUSTER_NAME` and `$DOMAIN_NAME` correspondingly):
`sudo ETCDCTL_API=3 etcdctl --ca-file=/etc/ssl/etcd/ca.crt --cert-file=/etc/ssl/etcd/client.crt --key-file=/etc/ssl/etcd/client.key --endpoints=https://etcd-0.etcd.$CLUSTER_NAME.k8s.$DOMAIN_NAME:2379 cluster-health`.
This should report that the cluster is healthy.

## Masters
There is currently only one master being created, for reasons of simplicity. It receives the
DNS name corresponding to that of the cluster, so that it can be contacted as the API
server of the Kubernetes cluster, but also the DNS name <cluster-name>-master-<index>.<domain-name>.

The kubeconfig file is copied to /etc/kubernetes/kubeconfig on every master node via SSH. Tectonic
assets are copied to only the first master node via SSH as well, as a zip archive, and gets
unzipped on the machine to /opt/tectonic via a script. After the latter operation, the bootkube
service gets enabled and started. If Tectonic is enabled, the tectonic service also gets enabled
and started.

## Workers
We create a number of workers corresponding to the variable `tectonic_worker_count`, which defaults
to 3. Each of these receives a DNS name <cluster-name>-worker-<index>.<domain-name>.

The kubeconfig file is copied to /etc/kubernetes/kubeconfig on every worker node via SSH.
