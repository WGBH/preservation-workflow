require 'fileutils'

abort("USAGE: #{$0} SOURCE METADATA DEST1 [ DEST2 ... ]") if ARGV.count < 3

def abort_unless(cmd, message)
  abort(message) unless ENV['CI'] || system("which #{cmd} > /dev/null")
end

abort_unless('sweep', 'Requires "sweep", a CLI to Sophos')
abort_unless('fits.sh', 'Add fits to PATH and chmod: "PATH=$PATH:/.../fits; chmod a+x "/.../fits/fits.sh"')

def message(message)
  puts "travis_fold:end:#{@last}" if @last
  puts "travis_fold:start:#{message}"
  puts message
  @last = message
end

source = ARGV.shift
metadata = ARGV.shift

Dir.mkdir(metadata)

################
# Sophos scan
################

message('sophos')

def sweep(filename)
  if ENV['CI']
    "fake sophos output\n"
  else
    `sweep "#{filename}"` # TODO: what if filename contains quotes?
  end
end

File.write("#{metadata}/#{File.basename(source)}-virus-scan.txt", sweep(source))

####################
# Clean filenames
####################

message('filenames')

def clean_names(source)
  bad_re = /[:;]/
  Dir.glob("#{source}/**/*").grep(bad_re).each do |file|
    if File.directory?(file)
      FileUtils.mkdir_p(file.gsub(bad_re, '_'))
    else
      FileUtils.mv(file, file.gsub(bad_re, '_'))
    end
  end
  `"find #{source} -type d -empty -delete"` # TODO
end

clean_names(source)

###############
# List files
###############

message('list')

File.write("#{metadata}/#{File.basename(source)}-file-list.txt", Dir.glob("#{source}/**/*").join("\n"))

##################
## Copy and Diff
##################
#
#copy_and_diff() {
#  L_SOURCE=$1
#  L_METADATA=$2
#  L_DEST=$3
#  cp -a $L_SOURCE $L_DEST
#  if [ "$HOOK" ]; then
#    eval "$HOOK"
#  fi
#  
#  mkdir -p $L_METADATA/diff
#
#  LC_ALL=C # Sort by ASCII: Differences in locale meant the traversal order was different.
#
#  diff -qrs $L_SOURCE $L_DEST >> $L_METADATA/diff/`basename $L_DEST`.diff
#}
#
#message 'copy_and_diff'
#
#while (( "$#" )); do
#  DEST=$1; shift
#  copy_and_diff $SOURCE $METADATA $DEST &
#  sleep 1
#  # sleep so that in tests, processes will not actually overlap.
#done
#
#########
## FITS
#########
#
#message 'fits'
#(
#  mkdir $METADATA/fits
#  if [ "$CI" = 'true' ]; then
#    for FILE in `find $SOURCE -type f`; do
#      touch $METADATA/fits/`basename $FILE`-fake-fits.xml
#    done
#  else
#    fits.sh -i $SOURCE -o $METADATA/fits -r
#  fi
#
#  for DOT_FILE in `find $METADATA/fits -regex '.*/\.[^/]*'`; do 
#    rm $DOT_FILE
#  done
#  
#  # -j: junk paths. pushd / popd is another alternative.
#  zip -jr $METADATA/fits.zip $METADATA/fits
#  for FITS in `ls $METADATA/fits/*`; do 
#    mv $FITS $FITS.txt
#  done
#) &
#
#########
## wait
#########
#
#wait
#
#echo "travis_fold:end:$LAST"
