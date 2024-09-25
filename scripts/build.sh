#!/bin/bash

set -e

# The environment to build the package for. Usually "default", but might be "nightly" or others.
MAX_CHANNEL="https://conda.modular.com/max"
ENV="${1-default}"
if [[ "${ENV}" == "--help" ]]; then
    echo "Usage: ENV - Argument 1 corresponds with the environment you wish to build the package for."
    exit 0
else if [[ "${ENV}" == "nightly" ]]; then
    MAX_CHANNEL="https://conda.modular.com/max-nightly"
fi

magic run template -m "${ENV}"
rattler-build build -r src -c "${MAX_CHANNEL}" -c conda-forge --skip-existing=all
rm src/recipe.yaml
