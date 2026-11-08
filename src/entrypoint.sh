#!/bin/sh
# Stirling PDF's init script creates symlinks under /usr/local/bin and needs
# root. TOS forbids root containers, so start the unmodified Spring Boot jar
# directly as uid 1000. /app/configs, /app/logs, /app/storage, /app/pipeline and
# /app/customFiles are symlinks into the mounted writable volumes.
set -u

for d in configs logs storage pipeline customFiles data; do
    mkdir -p "/$d" 2>/dev/null || true
done

export SERVER_PORT=8080
export STIRLING_TEMPFILES_DIRECTORY=/data

exec java -jar /app/app.jar
