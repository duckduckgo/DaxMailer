#!/usr/bin/env bash

SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" 1>/dev/null && pwd )

git stash
git checkout dev

while true ; do
    git pull origin dev
    carton install --deployment
    carton exec $SCRIPTDIR/db_migrate.pl
    echo "Hit [CTRL+C] to end this script"
    sleep 60
done
