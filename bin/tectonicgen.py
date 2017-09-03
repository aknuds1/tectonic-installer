#!/usr/bin/env python3
"""Tool to generate Tectonic Installer Terraform configurations.
"""
import argparse
import os.path
import sys
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
        Optional('etcdCount', default=3): int,
        Optional('etcdSize', default='512mb'): int,
        Optional('dropletImage', default='coreos-stable'): str,
        Optional('region', default='fra-1'): str,
        Optional('extraTags', default=[]): list,
        Optional('swapSize', default='1024m'): str,
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
    terraform_dir = os.path.join(build_dir, 'terraform')
    if not os.path.exists(terraform_dir):
        os.makedirs(terraform_dir)

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

    jinja_env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(searchpath='templates/digitalocean'),
        undefined=jinja2.StrictUndefined
    )
    template = jinja_env.get_template('etcd.tf.j2')
    output = template.render({
        'cluster_name': opts['clusterName'],
        'droplet_image': opts['dropletImage'],
        'region': opts['region'],
        'etcd_count': opts['etcdCount'],
        'etcd_size': opts['etcdSize'],
        'ssh_keys': opts['sshKeys'],
        'extra_tags': opts['extraTags'],
        'cluster_domain': opts['baseDomain'],
        'container_image': 'quay.io/coreos/etcd:v3.1.8',
        'swap_size': opts['swapSize'],
        'enable_swap': bool(opts['swapSize'].strip()),
        'initial_etcd_cluster_str': ','.join(initial_etcd_cluster_spec),
    })
    with open(os.path.join(terraform_dir, 'etcd.tf'), 'wt') as f:
        f.write('{}\n'.format(output))


_main()
