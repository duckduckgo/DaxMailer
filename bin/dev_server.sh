#!/usr/bin/env bash

SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" 1>/dev/null && pwd )
ROOTDIR=$SCRIPTDIR/..
PSGI_SCRIPT=$SCRIPTDIR/dev_server.psgi
LIBDIR=$ROOTDIR/lib
CARTONDIR=$ROOTDIR/local/lib/perl5/
CARTONBINDIR=$ROOTDIR/local/bin/
DB=$ROOTDIR/daxmailer.sqlite
PORT=5666
HOSTNAME=$(hostname)

[ "$DDGC_DB_DSN" == "" ]        && export DAXMAILER_DB_DSN="dbi:SQLite:dbname=$DB"
[ "$DBIC_TRACE_PROFILE" == "" ] && export DBIC_TRACE_PROFILE=console
[ "$DBIC_TRACE" == "" ]         && export DBIC_TRACE=1
[ "$DANCER_ENVIRONMENT" == "" ] && export DANCER_ENVIRONMENT=development

usage() {
    printf "Usage: $0 [-p port] [-mh]\n" 1>&2; exit 1;
}

help() {
    printf "\nUsage: $0 [-p port] [-mh]\n\n"
    printf "Options:\n\n"
    printf " -p     Specify listen port. Default: $PORT\n"
    printf " -m     Use local debug mail server on port 1025\n"
    printf " -h     Show this text\n\n"
    exit 0;
}

while getopts "p:mnh" o; do
    case "${o}" in
        h)
            help
            exit
            ;;
        p)
            PORT=${OPTARG}
            ;;
        m)
            m=1
            ;;
        *)
            usage
            ;;
    esac
done


if [ "$m" == "1" ] ; then
    # python -m smtpd -n -c DebuggingServer localhost:1025
    export DAXMAILER_SMTP_HOST="localhost:1025"
fi

export DAXMAILER_WEB_BASE=$( printf 'http://%s:%s' $HOSTNAME $PORT )

perl -I$CARTONDIR $CARTONBINDIR/plackup -R $LIBDIR -p $PORT -s Starman $PSGI_SCRIPT
