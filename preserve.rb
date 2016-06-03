require 'fileutils'

abort("USAGE: #{$0} SOURCE METADATA DEST1 [ DEST2 ... ]") if ARGV.count < 3

def abort_unless(cmd, message)
  abort(message) unless ENV['CI'] || system("which #{cmd} > /dev/null")
end

abort_unless('sweep', 'Requires "sweep", a CLI to Sophos')
abort_unless('fits.sh', 'Add fits to PATH and chmod: "PATH=$PATH:/.../fits; chmod a+x "/.../fits/fits.sh"')

def message(message)
  if ENV['CI']
    puts "travis_fold:end:#{@last}" if @last 
    puts "travis_fold:start:#{message}"
  end
  puts message
  @last = message
end

source = ARGV.shift
metadata = ARGV.shift
@hook = ARGV.shift if ARGV[0].match(' ')

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
  `find #{source} -type d -empty -delete` # TODO
end

clean_names(source)

###############
# List files
###############

message('list')

File.write(
  "#{metadata}/#{File.basename(source)}-file-list.txt",
  Dir.glob("#{source}/**/*").join("\n")
)

##################
# Copy and Diff
##################

@copy_diff_id = 0

def fork_copy_diff(source, metadata, dest)
  @copy_diff_id += 1
  fork do
    FileUtils.cp_r(source, dest)
    `@hook` if @hook
    FileUtils.mkdir_p("#{metadata}/diff")
    File.write(
      "#{metadata}/diff/#{File.basename(dest)}-#{@copy_diff_id}.diff",
      `diff -qrs #{source} #{dest}`
    )
  end
end

message('copy_and_diff')

ARGV.each do |dest|
  fork_copy_diff(source, metadata, dest)
end

#########
# FITS
#########

message('fits')

fork do
  FileUtils.mkdir_p("#{metadata}/fits")
  if ENV['CI']
    Dir.glob("#{source}/**/*") do |file|
      `touch #{metadata}/fits/#{File.basename(file)}-fake-fits.xml` if File.file?(file)
    end
  else
    `fits.sh -i #{source} -o #{metadata}/fits -r`
  end
  
  Dir.glob("#{metadata}/fits/*") do |file|
    File.unlink(file) if File.basename(file) =~ /^\./
  end
  
  `zip -jr #{metadata}/fits.zip #{metadata}/fits`
  
  Dir.glob("#{metadata}/fits/*") do |file|
    FileUtils.mv(file, "#{file}.txt")
  end
end

#########
# wait
#########

Process.wait

puts "travis_fold:end:#{@last}" if ENV['CI']
