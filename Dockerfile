# syntax=docker/dockerfile:1
# Keep the TT-RSS PHP-FPM image as the source of truth for PHP extensions,
# startup logic, updater scripts and the TT-RSS source tree.
ARG TTRSS_IMAGE=ghcr.io/tt-rss/tt-rss:latest
FROM ${TTRSS_IMAGE}

# The upstream app image is Alpine-based. Pre-create the app user/group
# and add Nginx + Supervisor to the same runtime.
RUN addgroup -g 1000 app \
    && adduser -D -h /var/www/html -G app -u 1000 app \
    && apk add --no-cache nginx supervisor \
    && mkdir -p /run/nginx /var/log/supervisor /var/log/nginx /var/log/php85 /var/www/html \
    && chmod -R 777 /run /tmp /var/log /var/www/html /etc/php85 \
    && rm -f /etc/nginx/http.d/default.conf

ENV APP_INSTALL_BASE_DIR=/var/www/html

COPY nginx/default.conf /etc/nginx/http.d/default.conf
COPY supervisord.conf /etc/supervisord.conf
COPY start-nginx.sh /usr/local/bin/start-nginx.sh
COPY shims/ /usr/local/bin/

RUN chmod 0755 /usr/local/bin/*

# blitz.cloud should route public HTTP traffic to this port.
EXPOSE 8080

# Keep this folder in blitz.cloud so the initialized TT-RSS working copy,
# local plugins/themes and runtime data survive app restarts.
VOLUME ["/var/www/html"]

ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]

# Clear the upstream image CMD; Supervisor is the only container command.
CMD []
