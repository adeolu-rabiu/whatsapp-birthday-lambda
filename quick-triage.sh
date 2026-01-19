#!/usr/bin/env bash
set -e
echo "== Times =="
date -Is
docker compose exec cron date -Is || true
echo
echo "== Cron logs (last 200) =="
docker compose logs --tail=200 cron || true
echo
echo "== API health =="
curl -s http://localhost:5000/health | jq . || true
echo
echo "== Bot health =="
curl -s http://localhost:3005/health | jq . || true
echo
echo "== Groups (Huawei) =="
curl -s "http://localhost:5000/groups?search=Huawei" | jq .
echo
echo "== Cron files =="
docker compose exec cron bash -lc 'crontab -l || true; echo; ls -l /etc/cron.d; echo; cat /etc/cron.d/* 2>/dev/null || true'
