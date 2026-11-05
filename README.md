# TT-RSS Blitz single-container image

This project combines the official TT-RSS PHP-FPM image with Nginx and Supervisor
in one container. It is intended for platforms such as blitz.cloud that expose
one HTTP port per app and isolate app filesystems.

## Architecture

- PHP-FPM: `127.0.0.1:9000` (not publicly exposed)
- Nginx: `0.0.0.0:8080` (the only public HTTP port)
- Updater: official `/opt/tt-rss/updater.sh`
- Persistent TT-RSS working tree: `/var/www/html`
- Database: external PostgreSQL / blitz.cloud Managed Database

The image reuses the official `ghcr.io/tt-rss/tt-rss` image for PHP extensions,
TT-RSS source and initialization scripts. Nginx and Supervisor are installed
into that image.

## Build locally

```sh
docker build -t tt-rss-blitz:local .
```

## Test locally with Compose

```sh
cp .env.example .env
# Edit .env and set strong passwords.
docker compose up -d --build
docker compose logs -f ttrss
```

Open `http://localhost:8080/tt-rss/`.

The local Compose file is for testing. It includes a local PostgreSQL service;
do not deploy that database as part of the blitz.cloud app if you use its
Managed Database.

## Publish to GHCR

1. Push this repository to GitHub on branch `main`.
2. The workflow `.github/workflows/publish.yml` builds `linux/amd64` and pushes
   `ghcr.io/OWNER/REPOSITORY:latest`.
3. In GitHub, open the package settings and make the package public if blitz.cloud
   needs to pull it without registry credentials.
4. In blitz.cloud choose **Host something new** -> **An app from Docker Hub**
   (the UI accepts public GHCR images), and enter the full image name.

## blitz.cloud settings

- Image: `ghcr.io/OWNER/REPOSITORY:latest`
- Port: `8080`
- Kept folder / persistent folder: `/var/www/html`
- Database: attach/create a PostgreSQL Managed Database.

Set these environment variables using the exact connection details shown by
blitz.cloud:

```text
TTRSS_DB_HOST=<managed-postgres-host>
TTRSS_DB_PORT=<managed-postgres-port>
TTRSS_DB_NAME=<database-name>
TTRSS_DB_USER=<database-user>
TTRSS_DB_PASS=<database-password>
TTRSS_SELF_URL_PATH=https://YOUR-APP.blitz.cloud/tt-rss
ADMIN_USER_PASS=<strong-admin-password>
```

Do not assume that a generic `DATABASE_URL` is automatically parsed by TT-RSS.
The official startup script expects the individual `TTRSS_DB_*` variables.
If blitz.cloud injects different variable names, map/copy the values into the
names above in the app Environment settings.

`TTRSS_SELF_URL_PATH` must exactly match the public app URL and include `/tt-rss`.
Do not set `HTTP_PORT`; Nginx listens on container port 8080.

## First start and persistence

On first boot, the official TT-RSS startup script initializes the working copy
under `/var/www/html/tt-rss`, configures the database and runs schema updates.
Keep `/var/www/html` persistent in blitz.cloud. If that folder is not kept,
local plugins, themes and runtime working-copy changes can be lost on recreation.

The image's `VOLUME` declaration is a hint to the platform; verify that blitz.cloud
actually keeps `/var/www/html` in the app's **Settings / Files** page.

## Logs and checks

- Nginx access log: stdout
- Nginx error log: stderr
- PHP-FPM and TT-RSS startup output: container logs
- Updater output: container logs

Check `https://YOUR-APP.blitz.cloud/tt-rss/healthz` after deployment.

## Important caveats

- This is a community integration image, not an official TT-RSS image.
- The upstream base image is currently referenced by `latest`. For reproducible
  production deployments, pin `TTRSS_IMAGE` to a tested immutable tag or digest
  and rebuild this image when TT-RSS releases updates.
- The upstream PHP-FPM image and its startup scripts can change. Test updates
  before promoting them.
- Confirm the managed PostgreSQL service allows connections from this app and
  whether it requires TLS. If TLS is required, configure the PostgreSQL SSL
  settings supported by the platform and PHP/libpq.
- This image runs Supervisor as PID 1 to manage PHP-FPM, Nginx and the updater.
