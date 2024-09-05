#!/bin/bash

TEMP_DIR=~/tmp
mkdir -p $TEMP_DIR

echo -e "[INFO] Building gojo package and copying tests."
mojo package src/gojo -o $TEMP_DIR/gojo.mojopkg
cp -R test/ $TEMP_DIR/test/
ls -la $TEMP_DIR

echo -e "[INFO] Running tests..."
mojo test $TEMP_DIR/test

echo -e "[INFO] Cleaning up the test directory."
rm -R $TEMP_DIR
