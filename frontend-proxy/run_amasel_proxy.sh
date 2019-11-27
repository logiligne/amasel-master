#!/bin/bash

NVM=/root/.nvm/nvm.sh
THIS_SCRIPT_DIR=$(dirname $0)

# Load NVM if not loaded already
if ! type nvm 2>&1 | head -n 1  | grep -q 'function'  ; then
	. $NVM
fi

nvm use default

exec node $THIS_SCRIPT_DIR/proxy.js
