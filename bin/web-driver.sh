#!/bin/bash

#------------------------------------------------------------------------
#ensure that bash is used
[ "$BASH_VERSION" ] || echo use bash!
[ "$BASH_VERSION" ] || exit 1

#------------------------------------------------------------------------
export SCRPFX=web #script prefix
export BASEDIR=$(cd $(dirname $0)/..; pwd)
LIB_NOLOGGER="" #set it to "" to log, set it to "something" to *not* log
F=$BASEDIR/bin/$SCRPFX-bootstrap.sh
if [ -f $F ]; then . $F; else echo cannot find $F - aborting...;exit 1; fi

#------------------------------------------------------------------------
#------------------------------------------------------------------------
usage(){
cat<<EOT
usage:
   $LIB_ME -a action

where:
   -a action: Action is one of
      - version: Show the current DocPad version installed
      - run: Run the web site in node.js for live update etc
      - build: Build a new version of the static web site
      - upgrade: Upgrade the local DocPad installation

EOT
}

#------------------------------------------------------------------------
#main code
logger_setLevel TRACE #trace to file
logger_info "$LIB_ME: start"
PATH=$PATH:/opt/Node/bin

#------------------------------------------------------------------------
#get parameters
while getopts a:d:f param; do
   case $param in
      f) FORCE=yes;;
      a) actions="$OPTARG";;
      d) logger_setLevel "$OPTARG";;
      h) usage; exit 0;;
   esac
done

#------------------------------------------------------------------------
if [ -z "$actions" ]; then
   usage; exit 1
fi

#------------------------------------------------------------------------
for action in $actions;do
   case $action in
      upgrade)
         cd $WEB_DOCPADDIR
         docpad upgrade
         #avoid bug in config-defs.js
         cp ../misc/config-defs.js /opt/Node/lib/node_modules/npm/node_modules/npmconf/config-defs.js
         docpad update
         echo check version:
         docpad --version
         echo check version:
         cd;docpad --version
         ;;

      version)
         cd $WEB_DOCPADDIR
         docpad --version
         ;;

      clean)
         logger_info clean $WEB_DPOUTDIR
         rm -rf $WEB_DPOUTDIR
         mkdir -p $WEB_DPOUTDIR
         ;;

      build)
         cd $WEB_DOCPADDIR
         docpad generate --env static
         #pagelist_generate
         ;;

      generate-poc)
         cd $LIB_BASEDIR
         perl $LIB_BINDIR/web-gen-poc.pl
         ;;

      generate-site)
         cd $LIB_BASEDIR
         perl $LIB_BINDIR/web-gen-site.pl
         ;;

      run)
         cd $WEB_DOCPADDIR
         docpad run --env static
         ;;
   esac
done


#------------------------------------------------------------------------
#done
logger_info "$LIB_ME: done"
