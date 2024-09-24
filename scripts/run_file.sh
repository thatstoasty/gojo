#!/bin/bash

set -e

FILE=${1}
TEMP_DIR=~/tmp
PACKAGE_NAME=gojo
mkdir -p $TEMP_DIR

echo "[INFO] Building $PACKAGE_NAME package and copying file."
cp -R $FILE $TEMP_DIR
magic run mojo package src/$PACKAGE_NAME -o $TEMP_DIR/$PACKAGE_NAME.mojopkg

echo "[INFO] Running file..."
readlink -f $TEMP_DIR/*.mojo | xargs -I {} magic run mojo {}

echo "[INFO] Cleaning up the tmp directory."
rm -R $TEMP_DIR
