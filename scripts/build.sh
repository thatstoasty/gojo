#!/bin/bash

set -e

# The environment to build the package for. Usually "default", but might be "nightly" or others.
ENVRIONMENT="${1-default}"
if [[ "${ENVRIONMENT}" == "--help" ]]; then
    echo "Usage: ENVRIONMENT - Argument 1 corresponds with the environment you wish to build the package for."
    exit 0
fi

magic run template -m "${ENVRIONMENT}"
rattler-build build -r src -c https://conda.modular.com/max -c conda-forge --skip-existing=all
rm src/recipe.yaml
