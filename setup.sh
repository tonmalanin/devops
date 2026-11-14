#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
docker compose up -d --build
echo 'Waiting for SSH...'
for i in $(seq 1 30); do
    if docker compose exec -T ansible-control ansible -i inventory.ini all -m ping >/dev/null 2>&1; then
        docker compose exec -T ansible-control ansible-playbook -i inventory.ini site.yml
        echo 'Check: curl -i http://localhost:8080/health'
        exit 0
    fi
    sleep 1
done
echo 'SSH is not ready; showing diagnostics:' >&2
docker compose exec -T ansible-control ansible -i inventory.ini all -m ping -v || true
docker compose logs --tail=30 nginxhost apphost >&2
exit 1
