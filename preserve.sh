#!/bin/bash
SOURCE=$1
METADATA=$2
DEST1=$3
DEST2=$4

die() { echo "$@" 1>&2 ; exit 1; }

if [ $# -lt 4 ]; then
  die "USAGE: $0 SOURCE METADATA DEST1 DEST2"
fi 

[ "$CI" = 'true' ] || which sweep   || die 'Requires "sweep", a CLI to Sophos'
[ "$CI" = 'true' ] || which fits.sh || die 'Add fits to PATH and chmod: "PATH=$PATH:/.../fits; chmod a+x "/.../fits/fits.sh"'

# Keep this after usage to keep output clean.
set -ex

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
) > $METADATA/`basename $SOURCE`-virus-scan.txt

###################
# Clean filenames
###################

find $SOURCE | perl -ne 'chomp; next unless /[:;,]/; $clean=$_; $clean=~s/[:;,]/_/g; `mv "$_" "$clean"`'
# TODO: just get the script that's currently in use...

##############
# List files
##############

find $SOURCE > $METADATA/`basename $SOURCE`-file-list.txt

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

mkdir $METADATA/diff
diff -qrs $SOURCE $DEST1 > $METADATA/diff/`basename $DEST1`-1.diff
diff -qrs $SOURCE $DEST2 > $METADATA/diff/`basename $DEST2`-2.diff

########
# FITS
########

mkdir $METADATA/fits
if [ "$CI" = 'true' ]; then
  for FILE in `find $SOURCE -type f`; do touch $METADATA/fits/`basename $FILE`-fake-fits.xml; done
else
  fits.sh -i $SOURCE -o $METADATA/fits -r
fi
zip -r $METADATA/fits.zip $METADATA/fits
for FITS in `ls $METADATA/fits/*`; do mv $FITS $FITS.txt; done
