#!/bin/bash
set -e

echo "🗄️ Ejecutando migraciones..."
cd /var/www
php artisan migrate --force || true

echo "🔗 Creando enlace simbólico de almacenamiento..."
php artisan storage:link || true

echo "🌱 Ejecutando seeders..."
php artisan db:seed --force || true

echo "🧹 Optimizando aplicación..."
php artisan optimize:clear
php artisan optimize

echo "✅ Build completado"
