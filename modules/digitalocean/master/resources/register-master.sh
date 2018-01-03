#!/bin/bash
set -ex

curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${1}" -d \
"{\"type\": \"assign\", \"droplet_id\": ${2}}" \
"https://api.digitalocean.com/v2/floating_ips/${3}/actions"
curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${1}" \
-d "{\"droplet_ids\": [${2}]}" "https://api.digitalocean.com/v2/load_balancers/${4}/droplets"
