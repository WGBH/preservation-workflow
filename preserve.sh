#!/bin/bash

die() { echo "$@" 1>&2 ; exit 1; }

message() {
  [ "$LAST" ] && echo "travis_fold:end:$LAST"
  echo "travis_fold:start:$1"
  echo $1
  LAST=$1
}

if [ $# -lt 3 ]; then
  die "USAGE: $0 SOURCE METADATA DEST1 [ DEST2 ... ]"
fi 

[ "$CI" = 'true' ] || which sweep   || die 'Requires "sweep", a CLI to Sophos'
[ "$CI" = 'true' ] || which fits.sh || die 'Add fits to PATH and chmod: "PATH=$PATH:/.../fits; chmod a+x "/.../fits/fits.sh"'

# Keep this after usage to keep output clean.
set -ex

SOURCE=$1; shift
METADATA=$1; shift

mkdir $METADATA

###############
# Sophos scan
###############

message 'sophos'
( 
  if [ "$CI" = 'true' ]; then
    echo 'fake sophos output'
  else
    sweep $SOURCE # TODO: any non-default parameters?
  fi
) > $METADATA/`basename $SOURCE`-virus-scan.txt

###################
# Clean filenames
###################

message 'filenames'
for DIR in `find $SOURCE -type d | grep '[:;]'`; do
  TARGET=`echo "$DIR" | sed 's/[:;]/_/g'`
  mkdir -p $TARGET
done
for FILE in `find $SOURCE ! -type d | grep '[:;]'`; do
  TARGET=`echo "$FILE" | sed 's/[:;]/_/g'`
  mv $FILE $TARGET
done
find . -type d -empty -delete

##############
# List files
##############

message 'list'
find $SOURCE > $METADATA/`basename $SOURCE`-file-list.txt

#################
# Copy and Diff
#################

copy_and_diff() {
  L_SOURCE=$1
  L_METADATA=$2
  L_DEST=$3
  cp -a $L_SOURCE $L_DEST
  if [ "$HOOK" ]; then
    eval "$HOOK"
  fi
  
  mkdir -p $L_METADATA/diff

  LC_ALL=C # Sort by ASCII: Differences in locale meant the traversal order was different.

  diff -qrs $L_SOURCE $L_DEST > $L_METADATA/diff/`basename $L_DEST`.diff
}

message 'copy_and_diff'

while (( "$#" )); do
  DEST=$1; shift
  copy_and_diff $SOURCE $METADATA $DEST &
  sleep 1
  # sleep so that in tests, processes will not actually overlap.
done

########
# FITS
########

message 'fits'
(
  mkdir $METADATA/fits
  if [ "$CI" = 'true' ]; then
    for FILE in `find $SOURCE -type f`; do
      touch $METADATA/fits/`basename $FILE`-fake-fits.xml
    done
  else
    fits.sh -i $SOURCE -o $METADATA/fits -r
  fi

  for DOT_FILE in `find $METADATA/fits -regex '.*/\.[^/]*'`; do 
    rm $DOT_FILE
  done
  
  # -j: junk paths. pushd / popd is another alternative.
  zip -jr $METADATA/fits.zip $METADATA/fits
  for FITS in `ls $METADATA/fits/*`; do 
    mv $FITS $FITS.txt
  done
) &

########
# wait
########

wait

echo "travis_fold:end:$LAST"