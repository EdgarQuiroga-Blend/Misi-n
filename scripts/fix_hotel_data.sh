#!/bin/bash
echo "🔧 Fixeando datos para JS perfecto..."

curl -X DELETE "localhost:9200/hotel_assets?ignore_unavailable=true" -k
sleep 1

curl -X PUT "localhost:9200/hotel_assets" -H 'Content-Type: application/json' -k -d'
{
  "mappings": {
    "properties": {
      "nombre": {"type": "text"},
      "tipo_servicio": {"type": "keyword"},
      "aplica_a": {"type": "keyword"},
      "precio": {"type": "integer"},
      "descripcion": {"type": "text"},
      "tags": {"type": "keyword"},
      "duracion_horas": {"type": "float"},
      "disponible": {"type": "boolean"}
    }
  }
}'

curl -X POST "localhost:9200/hotel_assets/_bulk" -H 'Content-Type: application/json' -k -d'
{"index":{"_id":"1"}}
{"nombre":"Hospedaje Premium Perros","tipo_servicio":"hospedaje","aplica_a":["perro"],"precio":85000,"duracion_horas":24,"descripcion":"Habitación CCTV 24/7","tags":["premium"],"disponible":true}
{"index":{"_id":"2"}}
{"nombre":"Hospedaje Gatos","tipo_servicio":"hospedaje","aplica_a":["gato"],"precio":65000,"duracion_horas":24,"descripcion":"Climatizado rascadores","tags":["confort"],"disponible":true}
{"index":{"_id":"3"}}
{"nombre":"Baño Medicinal Perros","tipo_servicio":"baño","aplica_a":["perro"],"precio":45000,"duracion_horas":2,"descripcion":"Antipulgas + secado","tags":["medico"],"disponible":true}
{"index":{"_id":"4"}}
{"nombre":"Veterinaria Completa","tipo_servicio":"veterinaria","aplica_a":["todos"],"precio":120000,"duracion_horas":1,"descripcion":"Revisión + vacunas","tags":["salud"],"disponible":true}
{"index":{"_id":"5"}}
{"nombre":"Baño Express","tipo_servicio":"baño","aplica_a":["perro"],"precio":25000,"duracion_horas":0.5,"descripcion":"Lavado rápido 30min","tags":["express"],"disponible":true}
{"index":{"_id":"6"}}
{"nombre":"Spa Relajante","tipo_servicio":"spa","aplica_a":["gato"],"precio":75000,"duracion_horas":1.5,"descripcion":"Aromaterapia masaje","tags":["spa"],"disponible":true}
'

echo "✅ $(curl -s "localhost:9200/hotel_assets/_count" -k | jq .count) servicios FIXEADOS!"
