#!/bin/sh

# script for execution of deployed applications

#

# Sets up the MATLAB Runtime environment for the current $ARCH and executes 

# the specified command.

#

exe_name=$0

currpath=$(dirname "$0")
exe_dir=~/Downloads/homer3_install
cd ~/Downloads

if [ -d "$exe_dir" ]; then
     echo TARGET DIR EXISTS
else
     echo TARGET DIR DOES NOT EXIST...Creating TARGET DIR
     mkdir "$exe_dir"
fi
cd "$exe_dir"
targetpath=$(pwd);
echo
echo "CURRENT DIR: " "$currpath"
echo "TARGET  DIR: " "$exe_dir"
echo
if [ "$currpath" != "$exe_dir" ]; then
     echo rm -rf $exe_dir
     rm -rf $exe_dir
	
     echo cp -r "$currpath" "$exe_dir"
     cp -r "$currpath" "$exe_dir"
	
     echo
fi

cd "$exe_dir"
currpath=$(pwd)

echo "NEW CURRENT PATH: " "$currpath"

rm -rf ~/libs; mkdir ~/libs
if [ ! -L "~/libs/mcr" ]; then ln -s /Applications/MATLAB/MATLAB_Runtime/v913 ~/libs/mcr; fi
libsdir=~/libs/mcr
exe_dir=~/Downloads/homer3_install
echo "------------------------------------------"
if [ "x$libsdir" = "x" ]; then
  echo Usage:
  echo    $0 \<deployedMCRroot\> args
else
  echo Setting up environment variables
  MCRROOT="$libsdir"
  echo ---
  DYLD_LIBRARY_PATH=.:${MCRROOT}/runtime/maci64 ;
  DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${MCRROOT}/bin/maci64 ;
  DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${MCRROOT}/sys/os/maci64;
  export DYLD_LIBRARY_PATH;
  echo DYLD_LIBRARY_PATH is ${DYLD_LIBRARY_PATH};
  shift 1
  args=
  while [ $# -gt 0 ]; do
      token=$libsdir
      args="${args} \"${token}\"" 
      shift
  done
  eval "\"${exe_dir}/setup.app/Contents/MacOS/setup\"" $args
fi
osascript -e 'tell application "Terminal" to quit' &

exit
