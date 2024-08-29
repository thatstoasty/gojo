#!/bin/bash

TEMP_DIR=~/tmp
mkdir -p $TEMP_DIR

echo -e "Building gojo package and copying tests."
./scripts/build.sh package
mv gojo.mojopkg $TEMP_DIR/
cp -R test/ $TEMP_DIR/test/

echo -e "\nBuilding binaries for all examples."
cd $TEMP_DIR
mojo test test
cd ..

echo -e "Cleaning up the test directory."
rm -R $TEMP_DIR
