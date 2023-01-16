#!/usr/bin/env bash

set -e

CMD=/usr/local/bin/mongod

if [ "$1" = "mongo" ]; then
    CMD="mongo"
fi

exec "$CMD" "$@"
