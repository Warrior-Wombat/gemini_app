#!/bin/sh

if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

exec "$@"
