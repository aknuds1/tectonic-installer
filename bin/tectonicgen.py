#!/usr/bin/env python3
"""Tool to generate Tectonic Installer Terraform configurations.
"""
import argparse
import os.path
import jinja2


os.chdir(os.path.join(os.path.dirname(__file__), '..'))


def _info(msg):
    sys.stdout.write('* {}\n'.format(msg))
    sys.stdout.flush()


def _main():
    cl_parser = argparse.ArgumentParser()
    cl_parser.add_argument('cluster_name')
    cl_parser.add_argument('ssh_keys', type=list)
    cl_parser.add_argument('base_domain')
    cl_parser.add_argument('--etcd_count', default=3, type=int)
    cl_parser.add_argument('--etcd_size', default='512mb')
    cl_parser.add_argument('--droplet_image', default='coreos-stable')
    cl_parser.add_argument('--region', default='fra1')
    cl_parser.add_argument('--extra_tags', type=list, default=[])
    cl_parser.add_argument('--swap_size', default='1024m')
    args = cl_parser.parse_args()

    build_dir = os.path.join('build', args.cluster_name)
    if not os.path.exists(build_dir):
        os.makedirs(args.cluster_name)
    terraform_dir = os.path.join(build_dir, 'terraform')
    if not os.path.exists(terraform_dir):
        os.makedirs(terraform_dir)

    cluster_domain = '{}.k8s.{}'.format(args.cluster_name, args.base_domain)
    initial_etcd_cluster_spec = []
    for i in range(args.etcd_count):
        etcd_name = '{}-etcd-{}'.format(args.cluster_name, i)
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
        'cluster_name': args.cluster_name,
        'droplet_image': args.droplet_image,
        'region': args.region,
        'etcd_count': args.etcd_count,
        'etcd_size': args.etcd_size,
        'ssh_keys': args.ssh_keys,
        'extra_tags': args.extra_tags,
        'cluster_domain': cluster_domain,
        'container_image': 'quay.io/coreos/etcd:v3.1.8',
        'swap_size': args.swap_size,
        'enable_swap': bool(args.swap_size.strip()),
        'initial_etcd_cluster_str': ','.join(initial_etcd_cluster_spec),
    })
    with open(os.path.join(terraform_dir, 'etcd.tf'), 'wt') as f:
        f.write('{}\n'.format(output))


_main()
