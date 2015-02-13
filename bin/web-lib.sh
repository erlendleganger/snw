#-----------------------------------------------------------------------
#lib settings
LIB_GENWARN="note: generated file, all local modifications will be lost"

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

#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
pagelist_generate(){
local me=pagelist_generate
logger_trace $me: start
local tmpfile=$(mktemp)
find $WEB_DPOUTDIR/{release/topic,misc} -name index.html|sort|sed -e "s/.*\/out//" -e "s/.*/'&',/">$tmpfile
pagelistfile=$WEB_DPOUTDIR/vendor/tipuesearch/page-list.g.js
logger_trace $me: generate $pagelistfile
cat >$pagelistfile <<EOT
//$LIB_GENWARN

//list of files to search
var tipuesearch_pages = [
$(cat $tmpfile)
''
];
EOT
rm $tmpfile
logger_trace $me: end
}
