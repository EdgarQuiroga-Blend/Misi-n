#!/bin/bash

echo "🏨 Creando índice HOTEL HPG..."

# Crear índice
curl -X PUT "localhost:9200/hotel_assets" -H 'Content-Type: application/json' -k -d'
{
  "settings": {"index": {"number_of_shards": 1, "number_of_replicas": 0}},
  "mappings": {
    "properties": {
      "id": {"type": "keyword"},
      "nombre": {"type": "text"},
      "mascota": {"type": "keyword"},
      "tipo": {"type": "keyword"},
      "descripcion": {"type": "text"},
      "precio": {"type": "integer"},
      "imagen": {"type": "keyword"},
      "disponible": {"type": "boolean"}
    }
  }
}'

# Datos reales del hotel
curl -X POST "localhost:9200/hotel_assets/_bulk" -H 'Content-Type: application/json' -k -d'
{"index":{"_id":"1"}}
{"nombre":"Hospedaje Premium Perros","mascota":"perro","tipo":"hospedaje","descripcion":"Habitación individual CCTV 24/7, paseo 3x día","precio":85000,"imagen":"perro-hospedaje.jpg","disponible":true}
{"index":{"_id":"2"}}
{"nombre":"Hospedaje Gatos","mascota":"gato","tipo":"hospedaje","descripcion":"Espacio climatizado con rascadores","precio":65000,"imagen":"gato-hospedaje.jpg","disponible":true}
{"index":{"_id":"3"}}
{"nombre":"Baño Medicinal Perros","mascota":"perro","tipo":"baño","descripcion":"Antipulgas + uñas + secado pro","precio":45000,"imagen":"perro-bano.jpg","disponible":true}
{"index":{"_id":"4"}}
{"nombre":"Spa Relajante Gatos","mascota":"gato","tipo":"spa","descripcion":"Masaje + aromaterapia","precio":75000,"imagen":"gato-spa.jpg","disponible":false}
{"index":{"_id":"5"}}
{"nombre":"Veterinaria Completa","mascota":"todos","tipo":"veterinaria","descripcion":"Revisión + vacunas","precio":120000,"imagen":"veterinario.jpg","disponible":true}
{"index":{"_id":"6"}}
{"nombre":"Baño Express","mascota":"perro","tipo":"baño","descripcion":"Lavado rápido 30min","precio":25000,"imagen":"perro-express.jpg","disponible":true}
'

echo "✅ $(curl -s "localhost:9200/hotel_assets/_count" -k | jq .count) servicios cargados!"
echo "📱 App lista: http://localhost:3000 (ajusta puerto)"
