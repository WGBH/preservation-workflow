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

###############
# Sophos scan
###############

mkdir $METADATA
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

##############
# List files
##############

find $SOURCE > $METADATA/files.txt

########
# Copy
########

cp -a $SOURCE $DEST1
cp -a $SOURCE $DEST2

# TODO: Diff

# TODO: Zip Fits

# TODO: Fits to .txt for FM
