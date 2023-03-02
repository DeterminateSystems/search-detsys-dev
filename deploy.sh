#!/usr/bin/env nix-shell
#!nix-shell -i bash ./shell.nix

set -euxo pipefail

PROJECT_NAME=search-nix

nix build .#dockerImages.x86_64-linux.default

# note: will write auth token to XDG_RUNTIME_DIR
(if [ ! -z "${FLY_API_TOKEN:-}" ]; then echo "$FLY_API_TOKEN"; else flyctl auth token; fi) | skopeo login -u x --password-stdin registry.fly.io
skopeo \
    --insecure-policy \
    copy docker-archive:"$(realpath ./result)" \
    docker://registry.fly.io/$PROJECT_NAME:latest \
    --format v2s2

flyctl deploy -i registry.fly.io/$PROJECT_NAME:latest --remote-only
