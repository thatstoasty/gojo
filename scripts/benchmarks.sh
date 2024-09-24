#!/bin/bash

set -e

TEMP_DIR=~/tmp
PACKAGE_NAME=gojo
mkdir -p $TEMP_DIR

echo "[INFO] Building $PACKAGE_NAME package and running benchmarks."
cp -a benchmarks/. $TEMP_DIR
magic run mojo package src/$PACKAGE_NAME -o $TEMP_DIR/$PACKAGE_NAME.mojopkg

echo "[INFO] Running benchmarks..."
magic run mojo $TEMP_DIR/scanner.mojo
magic run mojo $TEMP_DIR/string_builder.mojo
magic run mojo $TEMP_DIR/buffer.mojo

echo "[INFO] Cleaning up the benchmarks directory."
rm -R $TEMP_DIR
