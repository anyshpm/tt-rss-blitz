# syntax=docker/dockerfile:1
# Keep the TT-RSS PHP-FPM image as the source of truth for PHP extensions,
# startup logic, updater scripts and the TT-RSS source tree.
ARG TTRSS_IMAGE=ghcr.io/tt-rss/tt-rss:latest
FROM ${TTRSS_IMAGE}

# The upstream app image is Alpine-based. Add Nginx and Supervisor to the
# same runtime so Nginx can reach PHP-FPM over loopback.
RUN apk add --no-cache nginx supervisor \
    && mkdir -p /run/nginx /var/log/supervisor /var/www/html \
    && chmod -R 777 /run /var/log/supervisor /var/log/nginx /var/www/html \
    && rm -f /etc/nginx/http.d/default.conf

ENV APP_INSTALL_BASE_DIR=/var/www/html

COPY nginx/default.conf /etc/nginx/http.d/default.conf
COPY supervisord.conf /etc/supervisord.conf
COPY start-nginx.sh /usr/local/bin/start-nginx.sh

RUN chmod 0755 /usr/local/bin/start-nginx.sh

# blitz.cloud should route public HTTP traffic to this port.
EXPOSE 8080

# Keep this folder in blitz.cloud so the initialized TT-RSS working copy,
# local plugins/themes and runtime data survive app restarts.
VOLUME ["/var/www/html"]

ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]

# Clear the upstream image CMD; Supervisor is the only container command.
CMD []
