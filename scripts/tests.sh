#!/bin/bash

TEMP_DIR=~/tmp
mkdir -p $TEMP_DIR

echo "[INFO] Building gojo package and copying tests."
cp -R test/ $TEMP_DIR
mojo package src/gojo -o $TEMP_DIR/gojo.mojopkg

echo "[INFO] Running tests..."
mojo test $TEMP_DIR

echo "[INFO] Cleaning up the test directory."
rm -R $TEMP_DIR
