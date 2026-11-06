#!/bin/sh
set -eu

PHP_BIN="${TTRSS_PHP_EXECUTABLE:-/usr/bin/php${PHP_SUFFIX:-85}}"

echo "Waiting for PHP-FPM on 127.0.0.1:9000..."
until "$PHP_BIN" -r '$s = @fsockopen("127.0.0.1", 9000); exit($s ? 0 : 1);' >/dev/null 2>&1; do
    sleep 1
done

# If blitz.cloud passes a PORT env var that is not 80 or 8080, add it dynamically
if [ -n "${PORT:-}" ] && [ "$PORT" != "80" ] && [ "$PORT" != "8080" ]; then
    sed -i "s/listen 80;/listen 80;\n    listen $PORT;\n    listen [::]:$PORT;/" /etc/nginx/http.d/default.conf
fi

echo "PHP-FPM is ready; starting Nginx on :8080 and :80 ${PORT:+(and :$PORT)}."
exec nginx -g 'daemon off;'
