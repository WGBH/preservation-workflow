require 'fileutils'
require 'find'

abort("USAGE: #{$0} NO-HIDDEN [ OPTIONAL ] SOURCE METADATA DEST1 [ DEST2 ... ]") if ARGV.count < 3

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

hidden = true

if ARGV.first.upcase == 'NO-HIDDEN'
  hidden = false
  ARGV.shift
end

source = ENV['CI'] ? ARGV.shift : File.absolute_path(ARGV.shift) # Fixtures are hard with absolute path.
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
    `sweep '#{filename}'` # TODO: what if filename contains quotes?
  end
end

File.write("#{metadata}/#{File.basename(source)}-virus-scan.txt", sweep(source))

####################
# Clean filenames
####################

message('filenames')

def clean_names(source)
  bad_re = /[:;&!$^'"(){}*]/
  Find.find(source).grep(bad_re).each do |file|
    if File.directory?(file)
      FileUtils.mkdir_p(file.gsub(bad_re, '_'))
    else
      FileUtils.mv(file, file.gsub(bad_re, '_'))
    end
  end
  `find '#{source}' -type d -empty -delete` # TODO
end

clean_names(source)

####################
# Remove hidden files
####################

def remove_hidden_files(source)
  message('remove_hidden_files')
  hidden_files = []
  Find.find(source).each do |file|
    next if File.directory?(file)
    hidden_files << file if file.split('/')[-1] =~ /^\./
  end

  hidden_files.each { |path| File.delete(path) if File.exists?(path) }
end

remove_hidden_files(source) if hidden == false

###############
# List files
###############

message('list')

File.write(
  "#{metadata}/#{File.basename(source)}-file-list.txt",
  Find.find(source).to_a.sort.join("\n")
  # Sort for stable order across environments.
)

##################
# Copy and Diff
##################

def fork_copy_diff(source, metadata, dest, i)
  fork do
    FileUtils.cp_r(source, dest)
    # rsync = `rsync -a --exclude='.*' #{source} #{dest}`

    `#{ENV['HOOK']}` if ENV['HOOK']
    FileUtils.mkdir_p("#{metadata}/diff")
    diff = `diff -qrs --exclude='.*' '#{dest}' '#{source}'`.split("\n").sort.join("\n") + "\n"# Stable order
    diff_filename = "#{metadata}/diff/dest-#{i}.txt"
    File.write(diff_filename, diff)
    raise("diff not clean: #{diff_filename}") if $?.exitstatus != 0
  end
end

message('copy_and_diff')

ARGV.each_with_index do |dest, i|
  fork_copy_diff(source, metadata, dest, i)
end

Process.waitall

#########
# FITS
#########

message('fits')

fork do
  FileUtils.mkdir_p("#{metadata}/fits")
  if ENV['CI']
    Find.find(source) do |file|
      `touch '#{metadata}/fits/#{File.basename(file)}-fake-fits.xml'` if File.file?(file)
    end
  else
    `fits.sh -i '#{source}' -o '#{metadata}'/fits -r 2>&1`
    # Noise from FITS obscures stuff that really matters.
  end

  Find.find(metadata + '/fits') do |file|
    File.unlink(file) if File.basename(file) =~ /^\./ && File.file?(file)
  end

  `zip -jr '#{metadata}/fits.zip' '#{metadata}/fits'`

  Dir.glob("#{metadata}/fits/*") do |file|
    FileUtils.mv(file, "#{file}.txt")
  end
end

#########
# wait
#########

Process.waitall

puts "travis_fold:end:#{@last}" if ENV['CI']
