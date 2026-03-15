#!/bin/bash
set -e

echo "Waiting for OpenSearch to be fully ready..."
until curl -s http://localhost:9200/_cluster/health | grep -qE '"status":"(green|yellow)"'; do
  echo "Waiting for green/yellow status..."
  sleep 5
done

echo "✅ OpenSearch ready! Creating indices..."

curl -X PUT "localhost:9200/hpg-logs" -H 'Content-Type: application/json' -d'
{
  "settings": {"index": {"number_of_shards": 1, "number_of_replicas": 0}},
  "mappings": {
    "properties": {
      "timestamp": { "type": "date" },
      "level": { "type": "keyword" },
      "message": { "type": "text" },
      "service": { "type": "keyword" },
      "host": { "type": "keyword" }
    }
  }
}'

curl -X PUT "localhost:9200/hpg-metrics" -H 'Content-Type: application/json' -d'
{
  "settings": {"index": {"number_of_shards": 1, "number_of_replicas": 0}},
  "mappings": {
    "properties": {
      "timestamp": { "type": "date" },
      "service": { "type": "keyword" },
      "metric_name": { "type": "keyword" },
      "value": { "type": "float" },
      "unit": { "type": "keyword" },
      "labels": { "type": "object" }
    }
  }
}'

echo "✅ Índices creados exitosamente!"
echo "Listando índices:"
curl -s "localhost:9200/_cat/indices?v"
