#!/bin/bash
# Installs the package and checks whether the C++ dependency is being installed


# Aborts as soon as anything returns non-zero exit status
set -e
shopt -s dotglob

echo "======================================================================"
echo "SMOKE TEST"
echo "======================================================================"

echo "======================================================================"
echo "Packing the 'dredd-transactions' package into a tarball"
echo "======================================================================"
npm pack

echo "======================================================================"
echo "Preparing a temporary test directory"
echo "======================================================================"
SMOKE_DIR=~/test-temp/dredd-transactions-smoke
mkdir -p $SMOKE_DIR
cp ./*.tgz $SMOKE_DIR
cd $SMOKE_DIR
echo "package-lock=true" > .npmrc

# Initialize a test project
npm init -y

# Note: The lines below print the output of the 'npm install' commands
# and capture them for later introspection at the same time.

echo "======================================================================"
echo "Installing 'dredd-transactions' to the test project using tarball"
echo "======================================================================"
{ output1=$(npm install ./*.tgz --save | tee /dev/fd/5); } 5>&1

echo "======================================================================"
echo "Installing the test project from scratch using the lockfile"
echo "======================================================================"
{ output2=$(npm ci | tee /dev/fd/5); } 5>&1

echo "======================================================================"
echo "Adding an arbitrary new dependency to the test project"
echo "======================================================================"
{ output3=$(npm install left-pad --save | tee /dev/fd/5); } 5>&1

echo "======================================================================"
# Assert that Protagonist (the C++ dependency) was not installed
if [[ $output1 == *"protagonist"* ]] || \
    [[ $output2 == *"protagonist"* ]] || \
    [[ $output3 == *"protagonist"* ]] || \
    [[ -d './node_modules/protagonist' ]] || \
    [[ -d './node_modules/dredd-transactions/node_modules/protagonist' ]] || \
    [[ $(npm list | grep 'protagonist') ]] || \
    [[ $(cat './package-lock.json' | grep 'protagonist') ]]; then
  echo "ERROR: It looks like Dredd Transactions has tried to install"\
    "the 'protagonist' library (a C++ binding for the API Blueprint"\
    "parser), which is an unwanted behavior of the installation process."\
    "The packaging of Dredd Transactions should have prevented this."
  echo "======================================================================"
  exit 1
fi

echo "Importing 'dredd-transactions'"
echo "======================================================================"
echo "const assert = require('assert');" > index.js
echo "const dt = require('dredd-transactions');" >> index.js
echo "assert.ok(typeof dt.parse === 'function');" >> index.js
echo "assert.ok(typeof dt.compile === 'function');" >> index.js
node index.js

echo "======================================================================"
echo "Importing 'dredd-transactions/parse' and 'dredd-transactions/compile'"
echo "======================================================================"
echo "const assert = require('assert');" > index.js
echo "const parse = require('dredd-transactions/parse');" >> index.js
echo "const compile = require('dredd-transactions/compile');" >> index.js
echo "assert.ok(typeof parse === 'function');" >> index.js
echo "assert.ok(typeof compile === 'function');" >> index.js
node index.js

echo "======================================================================"
echo "Cleaning up"
echo "======================================================================"
rm -rf $SMOKE_DIR

echo "======================================================================"
echo "SUCCESS"
echo "======================================================================"
