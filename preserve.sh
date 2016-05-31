#!/bin/bash
set -ex
SOURCE=$1
METADATA=$2
DEST1=$3
DEST2=$4

if [ $# -lt 4 ]; then
  echo "USAGE: $0 SOURCE METADATA DEST1 DEST2"
  exit 1
fi 

mkdir $METADATA

###############
# Sophos scan
###############

( 
  if [ "$CI" = 'true' ]; then
    echo 'fake sophos output'
  else
    sweep $SOURCE # TODO: any non-default parameters?
  fi
) > $METADATA/sophos.txt

###################
# Clean filenames
###################

find $SOURCE | perl -ne 'chomp; next unless /[:;,]/; $clean=$_; $clean=~s/[:;,]/_/g; `mv "$_" "$clean"`'
# TODO: just get the script that's currently in use...

##############
# List files
##############

find $SOURCE > $METADATA/files.txt

########
# Copy
########

cp -a $SOURCE $DEST1
cp -a $SOURCE $DEST2

########
# Hook
########

if [ "$HOOK" ]; then
  eval $HOOK
fi

########
# Diff
########

diff -qr $SOURCE $DEST1
diff -qr $SOURCE $DEST2

########
# FITS
########

# TODO: Zip Fits

# TODO: Fits to .txt for FM
