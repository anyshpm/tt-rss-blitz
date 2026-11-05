#!/bin/sh
set -eu

PHP_BIN="${TTRSS_PHP_EXECUTABLE:-/usr/bin/php${PHP_SUFFIX:-85}}"

echo "Waiting for PHP-FPM on 127.0.0.1:9000..."
until "$PHP_BIN" -r '$s = @fsockopen("127.0.0.1", 9000); exit($s ? 0 : 1);' >/dev/null 2>&1; do
    sleep 1
done

echo "PHP-FPM is ready; starting Nginx on :8080."
exec nginx -g 'daemon off;'
