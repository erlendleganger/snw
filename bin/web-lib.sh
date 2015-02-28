#-----------------------------------------------------------------------
#lib settings
export LIB_GENWARN="note: generated file, all local modifications will be lost"

#-----------------------------------------------------------------------
#basedir must be set in calling script
if [ "$BASEDIR" ]; then
   export LIB_BASEDIR=$BASEDIR
else
   echo error - BASEDIR not set
   exit 1
fi

#-----------------------------------------------------------------------
#the bin directory
export LIB_BINDIR=$LIB_BASEDIR/bin

#-----------------------------------------------------------------------
#the log directory
export LIB_LOGDIR=$LIB_BASEDIR/log

#-----------------------------------------------------------------------
#the data directory
export LIB_DATADIR=$LIB_BASEDIR/src/data
export LIB_TOPICDIR=$LIB_BASEDIR/src/topic

#-----------------------------------------------------------------------
#the file name of the script; excluding any path part
export LIB_ME=$(basename $0)

#-----------------------------------------------------------------------
#set log4sh configuration file 
export LOG4SH_CONFIGURATION=$LIB_BINDIR/log4sh.properties
source $LIB_BINDIR/log4sh

#-----------------------------------------------------------------------
#configure the output file to use with the file logger
export LIB_LOGFILE=~/var/log/$LIB_ME.log
appender_file_setFile myLogfile $LIB_LOGFILE

#-----------------------------------------------------------------------
export WEB_DOCPADDIR=$LIB_BASEDIR/docpad
export WEB_DPOUTDIR=$LIB_BASEDIR/docpad/out
export WEB_GENDIR=$LIB_BASEDIR/gen

#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
tbd(){
local me=tbd
logger_trace $me: start
logger_trace $me: end
}

#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
convert_db(){
local me=convert_db
local id=dummy
logger_trace $me: start
perl -we "
use lib qq($LIB_BINDIR); #to find web.pm
use web;
web::convert_db(qw($id));
" 2>&1|logger_info
if [ ${PIPESTATUS[0]} != 0 ]; then
   logger_fatal $me: conversion failed; exit 1
fi
logger_trace $me: end
}

