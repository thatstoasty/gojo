#!/bin/bash

TEMP_DIR=~/tmp
mkdir -p $TEMP_DIR

echo "[INFO] Building gojo package and running benchmarks."
cp -R benchmarks/ $TEMP_DIR
magic run mojo package src/gojo -o $TEMP_DIR/gojo.mojopkg

echo "[INFO] Running benchmarks..."
magic run mojo $TEMP_DIR/scanner.mojo
magic run mojo $TEMP_DIR/string_builder.mojo

echo "[INFO] Cleaning up the benchmarks directory."
rm -R $TEMP_DIR
