#!/bin/bash

NVM=/root/.nvm/nvm.sh
THIS_SCRIPT_DIR=$(dirname $0)
LOG_DIR=$THIS_SCRIPT_DIR/../logs
LOG_FILE=$LOG_DIR/amasel_syncer.log

mkdir -p $LOG_DIR
# Load NVM if not loaded already
if ! type nvm 2>&1 | head -n 1  | grep -q 'function'  ; then
	. $NVM
fi

nvm use default

exec coffee $THIS_SCRIPT_DIR/amasel_syncer.coffee 2>&1 >>$LOG_FILE
