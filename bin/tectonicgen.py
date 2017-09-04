#!/usr/bin/env python3
"""Tool to generate Tectonic Installer Terraform configurations.
"""
import argparse
import os.path
import subprocess
import sys
import shutil
import jinja2
import yaml
from schema import Schema, Or, Optional


os.chdir(os.path.join(os.path.dirname(__file__), '..'))


def _info(msg):
    sys.stdout.write('* {}\n'.format(msg))
    sys.stdout.flush()


def _read_opts(args):
    schema = Schema({
        'platform': str,
        'clusterName': str,
        'baseDomain': str,
        'doToken': str,
        'sshKeys': Or(str, list),
        'adminEmail': str,
        'adminPasswordHash': str,
        Optional('workerCount', default=3): int,
        Optional('updateChannel', default='tectonic-1.7-production'): str,
        Optional('licensePath'): str,
        Optional('pullSecretPath'): str,
        Optional('etcdCount', default=3): int,
        Optional('etcdSize', default='512mb'): int,
        Optional('masterSize', default='2gb'): int,
        Optional('workerSize', default='2gb'): int,
        Optional('dropletImage', default='coreos-stable'): str,
        Optional('region', default='fra1'): str,
        Optional('extraTags', default=[]): list,
        Optional('swapSize', default='1024m'): str,
        Optional('disableTectonic', default=False): bool,
        Optional(
            'updateAppId', default='6bc7b986-4654-4a0f-94b3-84ce6feb1db4'
        ): str,
        Optional(
            'updateServer', default='https://tectonic.update.core-os.net'
        ): str,
        Optional(
            'statsUrl', default='https://stats-collector.tectonic.com'
        ): str,
        Optional('imageRe', default='/^([^/]+/[^/]+/[^/]+):(.*)$/'): str,
        Optional('doSshKeyPath', default=os.path.expanduser('~/.ssh/id_rsa')):
            str,
    })
    with open(args.settings, 'rt') as f:
        opts = yaml.load(f.read())
    assert isinstance(opts, dict), opts
    opts = schema.validate(opts)
    if not isinstance(opts['sshKeys'], list):
        opts['sshKeys'] = [opts['sshKeys']]
    opts['sshKeys'] = [str(x) for x in opts['sshKeys']]
    # XXX: Only supported platform for now
    assert opts['platform'] == 'digitalocean'
    return opts


def _get_tf_list(l):
    assert isinstance(l, list)
    return '[{}]'.format(', '.join(['"{}"'.format(x) for x in l]))


def _get_tf_map(d):
    assert isinstance(d, dict)
    tf_map = '{\n'
    for k, v in d.items():
        tf_map += '    "{}" = "{}"\n'.format(k, v)
    tf_map += '  }'
    return tf_map


def _get_tf_bool(b):
    return str(bool(b)).strip().lower()


_container_images = {
    'addon_resizer': 'gcr.io/google_containers/addon-resizer:2.1',
    'alertmanager': 'quay.io/prometheus/alertmanager:v0.8.0',
    'awscli': 'quay.io/coreos/awscli:025a357f05242fdad6a81e8a6b520098aa65a600',
    'bootkube': 'quay.io/coreos/bootkube:v0.6.1',
    'calico': 'quay.io/calico/node:v2.4.1',
    'calico_cni': 'quay.io/calico/cni:v1.10.0',
    'config_reload': 'quay.io/coreos/configmap-reload:v0.0.1',
    'console': 'quay.io/coreos/tectonic-console:v1.9.3',
    'error_server': 'quay.io/coreos/tectonic-error-server:1.0',
    'etcd': 'quay.io/coreos/etcd:v3.1.8',
    'etcd_operator': 'quay.io/coreos/etcd-operator:v0.4.2',
    'flannel': 'quay.io/coreos/flannel:v0.8.0-amd64',
    'flannel_cni': 'quay.io/coreos/flannel-cni:0.1.0',
    'heapster': 'gcr.io/google_containers/heapster:v1.4.1',
    'hyperkube': 'quay.io/coreos/hyperkube:v1.7.3_coreos.0',
    'identity': 'quay.io/coreos/dex:v2.6.1',
    'ingress_controller': 'gcr.io/google_containers/nginx-ingress-controller'
    ':0.9.0-beta.11',
    'kenc': 'quay.io/coreos/kenc:0.0.2',
    'kubedns': 'gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.4',
    'kubednsmasq': 'gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64'
    ':1.14.4',
    'kubedns_sidecar': 'gcr.io/google_containers/k8s-dns-sidecar-amd64:1.14.4',
    'kube_state_metrics': 'quay.io/coreos/kube-state-metrics:v1.0.0',
    'kube_version': 'quay.io/coreos/kube-version:0.1.0',
    'kube_version_operator': 'quay.io/coreos/kube-version-operator'
    ':v1.7.3-kvo.3',
    'node_agent': 'quay.io/coreos/node-agent:v1.7.3-kvo.3',
    'node_exporter': 'quay.io/prometheus/node-exporter:v0.14.0',
    'pod_checkpointer': 'quay.io/coreos/pod-checkpointer:'
    '3517908b1a1837e78cfd041a0e51e61c7835d85f',
    'prometheus': 'quay.io/prometheus/prometheus:v1.7.1',
    'prometheus_config_reload': 'quay.io/coreos/prometheus-config-reloader:'
    'v0.0.2',
    'prometheus_operator': 'quay.io/coreos/prometheus-operator:v0.11.1',
    'stats_emitter': 'quay.io/coreos/tectonic-stats:6e882361357fe4b773adb'
    'f279cddf48cb50164c1',
    'stats_extender': 'quay.io/coreos/tectonic-stats-extender:487b3da4e175d'
    'a96dabfb44fba65cdb8b823db2e',
    'tectonic_channel_operator': 'quay.io/coreos/tectonic-channel-operator:'
    '0.5.3',
    'tectonic_etcd_operator': 'quay.io/coreos/tectonic-etcd-operator:v0.0.2',
    'tectonic_monitoring_auth': 'quay.io/coreos/tectonic-monitoring-auth:'
    'v0.0.1',
    'tectonic_prometheus_operator': 'quay.io/coreos/tectonic-prometheus-'
    'operator:v1.5.2',
    'tectonic_cluo_operator': 'quay.io/coreos/tectonic-cluo-operator:v0.1.3'
}

_versions = {
    'alertmanager': 'v0.8.0',
    'etcd': '3.1.8',
    'kubernetes': '1.7.3+tectonic.1',
    'monitoring': '1.5.2',
    'prometheus': 'v1.7.1',
    'tectonic': '1.7.3-tectonic.1',
    'tectonic-etcd': '0.0.1',
    'cluo': '0.1.3'
}


def _render_template(
    root, fname, opts, build_dir, template_dir, cluster_domain,
    initial_etcd_cluster_spec, license_path, pull_secret_path,
):
    etcd_dns_names = [
        'etcd-{}.etcd.{}'.format(i, cluster_domain) for i in
        range(opts['etcdCount'])
    ]
    jinja_env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(searchpath='.'),
        undefined=jinja2.StrictUndefined
    )
    template = jinja_env.get_template(os.path.join(root, fname))
    output = template.render({
        'do_token': opts['doToken'],
        'cluster_name': opts['clusterName'],
        'droplet_image': opts['dropletImage'],
        'region': opts['region'],
        'etcd_count': opts['etcdCount'],
        'etcd_size': opts['etcdSize'],
        'master_size': opts['masterSize'],
        'ssh_keys': _get_tf_list(opts['sshKeys']),
        'extra_tags': _get_tf_list(opts['extraTags']),
        'base_domain': opts['baseDomain'],
        'cluster_domain': cluster_domain,
        'console_domain': 'console.{}'.format(cluster_domain),
        'container_image': 'quay.io/coreos/etcd:v3.1.8',
        'swap_size': opts['swapSize'],
        'enable_swap': _get_tf_bool(opts['swapSize'].strip()),
        'initial_etcd_cluster_str': ','.join(initial_etcd_cluster_spec),
        'service_cidr': '10.3.0.0/16',
        'cluster_cidr': '10.2.0.0/16',
        'etcd_dns_names': _get_tf_list(etcd_dns_names),
        'container_images': _get_tf_map(_container_images),
        'disable_tectonic': opts['disableTectonic'],
        'versions': _get_tf_map(_versions),
        'tectonic_license_path': license_path,
        'pull_secret_path': pull_secret_path,
        'admin_email': opts['adminEmail'],
        'admin_password_hash': opts['adminPasswordHash'],
        'update_channel': opts['updateChannel'],
        'update_app_id': opts['updateAppId'],
        'update_server': opts['updateServer'],
        'stats_url': opts['statsUrl'],
        'image_re': opts['imageRe'],
        'flannel_image': _container_images['flannel'],
        'flannel_cni_image': _container_images['flannel_cni'],
        'kube_version_image_url':
            _container_images['kube_version'].split(':')[0],
        'kube_version_image_tag':
            _container_images['kube_version'].split(':')[1],
        'hyperkube_image_url':
            _container_images['hyperkube'].split(':')[0],
        'hyperkube_image_tag':
            _container_images['hyperkube'].split(':')[1],
        'do_ssh_key_path': opts['doSshKeyPath'],
        'worker_count': opts['workerCount'],
        'worker_size': opts['workerSize'],
    })
    dpath = os.path.relpath(root, template_dir)
    tgt_fpath = os.path.normpath(
        os.path.join(build_dir, dpath, os.path.splitext(fname)[0])
    )
    tgt_dpath = os.path.dirname(tgt_fpath)
    if not os.path.exists(tgt_dpath):
        os.makedirs(tgt_dpath)
    print('Rendering {}'.format(tgt_fpath))
    with open(tgt_fpath, 'wt') as f:
        f.write('{}\n'.format(output))


def _main():
    cl_parser = argparse.ArgumentParser()
    cl_parser.add_argument('settings')
    args = cl_parser.parse_args()

    opts = _read_opts(args)
    _info(
        'Generating Terraform configuration for \'{}\' cluster'.format(
            opts['clusterName']
        )
    )

    build_dir = os.path.join('build', opts['clusterName'])
    if not os.path.exists(build_dir):
        os.makedirs(opts['clusterName'])

    cluster_domain = '{}.k8s.{}'.format(
        opts['clusterName'], opts['baseDomain']
    )
    initial_etcd_cluster_spec = []
    for i in range(opts['etcdCount']):
        etcd_name = '{}-etcd-{}'.format(opts['clusterName'], i)
        etcd_address = 'etcd-{}.etcd.{}'.format(i, cluster_domain)
        initial_etcd_cluster_spec.append('{}=https://{}:2380'.format(
            etcd_name, etcd_address
        ))
    if not opts['disableTectonic']:
        license_path_src = os.path.abspath(opts['licensePath'])
        license_path = os.path.basename(license_path_src)
        shutil.copy2(license_path_src, os.path.join(
            build_dir, license_path
        ))
        pull_secret_path_src = os.path.abspath(opts['pullSecretPath'])
        pull_secret_path = os.path.basename(pull_secret_path_src)
        shutil.copy2(
            pull_secret_path_src, os.path.join(build_dir, pull_secret_path)
        )
    else:
        license_path = '/dev/null'
        pull_secret_path = '/dev/null'

    template_dir = 'templates/digitalocean'
    for root, dnames, fnames in os.walk(template_dir):
        for fname in [fname for fname in fnames if fname.endswith('.j2')]:
            _render_template(
                root, fname, opts, build_dir, template_dir, cluster_domain,
                initial_etcd_cluster_spec, license_path, pull_secret_path,
            )

    resources_path = os.path.join(build_dir, 'resources')
    if os.path.exists(resources_path):
        os.remove(resources_path)
    os.symlink(
        '../../templates/digitalocean/resources',
        resources_path
    )

    os.chdir(build_dir)
    subprocess.check_call(['terraform', 'get', ])
    subprocess.check_call(['terraform', 'init', ])
    subprocess.check_call(['terraform', 'validate', ])


_main()
