#-----------------------------------------------------------------------
#this script sources common script libraries

#=======================================================================
#=======================================================================
bootstrap_load_lib(){
local me=$(basename $0)
local f
local srclist="
$BASEDIR/bin/$SCRPFX-lib.sh
"
for f in $srclist; do
   if [ -f $f ]; then
      echo $me: sourcing $f...
      . $f
   else
      echo $me: cannot find $f - aborting...
      exit 1
   fi
done
}

#-----------------------------------------------------------------------
#source the libraries
bootstrap_load_lib

