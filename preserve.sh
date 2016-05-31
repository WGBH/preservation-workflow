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

# TODO: Sophos scan

mkdir $METADATA
touch $METADATA/fake-sophos.txt

# TODO: Clean filenames

# TODO: Copy

cp -a $SOURCE $DEST1
cp -a $SOURCE $DEST2

# TODO: post-Copy hook to introduce errors and see how they are handled

# TODO: Diff

# TODO: Zip Fits

# TODO: Fits to .txt for FM
