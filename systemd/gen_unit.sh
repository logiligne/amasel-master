#!/bin/bash

THIS_SCRIPT_DIR=`$(cd $(dirname $0)); pwd`
INSTALL_DIR=`dirname $THIS_SCRIPT_DIR`
NAME=`basename $INSTALL_DIR`

DESC="Amasel Sync Service for $NAME"
EXEC_START=$INSTALL_DIR/worker/run_amasel_syncer.sh

if [[ "$1" ]]; then
	DESC="Amasel systemd wrapper for `basename $1`"
	EXEC_START=`realpath $1`
fi

cat > $NAME.service <<HERE
[Unit]
Description=$DESC
Requires=network-online.target
After=network-online.target

[Service]
ExecStart=$EXEC_START

[Install]
WantedBy=multi-user.target
HERE
