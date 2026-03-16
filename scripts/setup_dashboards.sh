#!/bin/bash
echo "🎛️ Configurando Dashboards..."

sleep 5

curl -X POST "localhost:5601/api/saved_objects/index-pattern/hotel_assets" \
  -H "kbn-xsrf: true" \
  -H "Content-Type: application/json" \
  -k -d'{
    "attributes": {
      "title": "hotel_assets*",
      "timeFieldName": "@timestamp"
    }
  }' > /dev/null 2>&1 || echo "Index pattern ya existe"

echo "✅ Dashboards listo!"
echo "🌐 ABRIR: http://localhost:5601/app/discover"
echo "📱 APP WEB: Verifica puerto de tu servidor"
