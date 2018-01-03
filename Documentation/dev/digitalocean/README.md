# Tectonic Installer for DigitalOcean
This is Tectonic Installer for the [DigitalOcean](http://digitalocean.com/) hosting platform.

## etcd

### Testing
In order to test the etcd cluster, SSH into one of the etcd nodes and issue the following command
(setting `$CLUSTER_NAME` and `$DOMAIN_NAME` correspondingly):
`sudo ETCDCTL_API=3 etcdctl --cacert=/etc/ssl/etcd/ca.crt --cert=/etc/ssl/etcd/client.crt --key=/etc/ssl/etcd/client.key --endpoints=https://$CLUSTER_NAME-etcd-0.$DOMAIN_NAME:2379 endpoint health`.
This should report that the cluster is healthy.

## Masters
There is currently only one master being created, for reasons of simplicity. It receives the
DNS name <cluster-name>-api.<domain-name>, so that it can be contacted as the API server of the
Kubernetes cluster, but also the DNS name <cluster-name>-master-<index>.<domain-name>.

## Workers
We create a number of workers corresponding to the variable `tectonic_worker_count`, which defaults
to 3. Each of these receives a DNS name <cluster-name>-worker-<index>.<domain-name>.

## Host Name Resolution
Every master and worker node is configured, via /etc/systemd/resolved.conf, to resolve hostnames
within the base domain. This is because Kubernetes expects to be able to resolve the unqualified
hostnames of its nodes, and will fail otherwise.
