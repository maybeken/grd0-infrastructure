FROM docker.io/library/nextcloud:fpm-alpine
RUN ["apk", "add", "ffmpeg", "nodejs", "shadow"]
RUN ["groupmod", "--gid", "1000", "www-data"]
RUN ["usermod", "--uid", "1000", "www-data"]