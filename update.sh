#!/usr/bin/env nix-shell
#!nix-shell -i bash ./shell.nix

set -euxo pipefail

./config-generator/update-hound.py > config-generator/hound.json
nix build .#dockerImages.x86_64-linux.default

