#!/bin/sh

if [ -f /app/.env ]; then
  export $(cat /app/.env | grep -v '^#' | xargs)
fi

exec "$@"
