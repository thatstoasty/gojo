#!/bin/bash
mkdir -p tmp

echo -e "Building gojo package and copying tests."
./scripts/build.sh package
mv gojo.mojopkg tmp/
cp -R tests/ tmp/tests/

echo -e "\nBuilding binaries for all examples."
cd tmp
pytest tests
cd ..

echo -e "Cleaning up the test directory."
rm -R tmp
