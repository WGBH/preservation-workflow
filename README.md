# preservation-workflow

[![Build Status](https://travis-ci.org/WGBH/preservation-workflow.svg?branch=master)](https://travis-ci.org/WGBH/preservation-workflow)

This repository contains useful scripts to help automate common WGBH Media Library and Archive digital preservation workflows into a single `preserve.rb` Ruby script.

This script will:
- Scan source directory for viruses using Sophos
- Create text file list of all source directory folders and files
- Copy source directory and files to one or more destination directories
- Compare source and destination files for differences and report those results in a text file
- Run FITS [(File Information Tool Set)](http://projects.iq.harvard.edu/fits/home) on source directory and create FITS xml for all files

Our digital preservation workflow has two goals.  The first being to sucessfully copy files from the source destination to our preservation and offsite destinations.
The second goal is to create tehcnical metadata XML that we process and store in another system.  The script in this repository helps us to do that in a efficient way.

**Software Dependencies**

Here is a list of the software you'll need to run `preserve.rb` assuming you're running on a recent Mac OS X machine.

- FITS (and Java 1.7 or higher)
- Git
- Ruby
- Sophos anti-virus
- preservation-workflow repository cloned from Github

If you don't have Sophos, you can try commenting out any refrences to `sweep` and virus scanning in `preserve.rb`.

**How It Works**

The preserve.rb script, when given the proper SOURCE, METADATA, and DESTINATION(S) will first run `sweep` which is a command used by Sophos Anti-Virus to run a virus scan.  

The text log of that scan is saved in the METADATA directory specified. 
Next the script seeks out the bad filenames that impact the copying to LTO tape and changes them automatically.  Then it writes a text file list of all the folders and files within the SOURCE directory specified.

Next, it begins the Copy and Diff process which copies SOURCE to DESTINATION.  If there are multiple destinations, the copying happens at the same time.  When the copying has completed, the script then runs a diff comparison for every SOURCE file to it's copy DESTINATION file.  A text diff report file is created and saved in the METADATA directory, this file includes the list of successful transfers as well.

At the same time Copy and Diff are running, the SOURCE files are being processed by FITS and technical metadata xml is being created for every SOURCE file.  This usually finishes after the Copy and Diff process.  When it's finished running, the xml files are zipped and the unzipped xml is renamed to .txt for easier processing and review.

**Bonus Feature!**

The `file-list.txt` files that get created in the METADATA folder can be imported to [this web app](http://wgbh.github.io/preservation-workflow/) and users can browse the file system just as they would in a Finder window.  Users can expand folders and copy folder or file names.  This can be useful for file path browsing or database grooming.

**Running preserve.rb**

In Terminal, change directory to where you've cloned the preservation-workflow Github repository.
```
$ cd preservation-workflow
```

Next you need to set the PATH.  PATH is looking for the location of your download of the latest version of FITS.
```
$ PATH=$PATH:/path/to/fits-0.10.2
```

Now you should be good to run preserve.rb
```
$ ruby preserve.rb /path/to/SOURCE /path/to/METADATA /path/to/DESTINATION1 /path/to/DESTINATION2
```
**NOTE**

The script will want to create the folders you specify as METADATA, DESTINATION1, DESTINATION2 etc.  
So just know the last directory in the file paths you specify for those will be created when preservation.rb is run.  If you want to preserve folder path's from higher up in the SOURCE drive, you need to create those folders first before you run preserve.rb

*Example*

Your source directory path is `/volumes/hard_drive/Folder1234/Program_1234`
You need to create folders on the destination like this `/volumes/destination/Folder1234`
So when you run preserve.rb it will look like this 
```
$ ruby preserve.rb /volumes/hard_drive/Folder1234/Program_1234 /path/to/METADATA /volumes/destination/Folder1234/Program_1234
```

**Destinations**

You can specify a single DESTINATION or as many DESTINATION locations as you like.  These are where you will be creating copies of the source files.
The first process that will run is sweep which will run a virus scan and report the results in the METADATA directory.  When it completes and creates the "virus-scan.txt" file review it and make sure it didn't find any viruses.  If it did, stop preserve.rb and investiage.  If no virus or other threats were found, sit back and relax until the full preserve.rb processes complete.  It could a while depending on the size of the files you are preserving and how many destinations you have.
When everything is finished processing, if there were differences reported during the Copy and Diff section you will see a notification of that in Terminal looking something like.
```
preserve.rb:87:in `block in fork_copy_diff': diff not clean: /path/to/METADATA/diff/dest-0.txt (RuntimeError)
```
A difference means that some of the files either didn't copy or the they didn't copy exactly as the source.
If that's the case, then look at the diff log file mentioned above in the METADATA directory to see which files do not match.
You can verify for yourself by running `md5` in Terminal.
```
$ md5 /path/to/SOURCE/diff_file1
$ md5 /path/to/DESTINATION/diff_file1
```
If the md5 results do not match, there is an actual difference in the file and you should replace it on that DESTINATION and run md5 checks or run the entire preservation.rb process again.
If the md5 results are the same, the files actually do match and are identical.  Make note of that in the diff log file in the METADATA directory.

And that's it.  If everything runs successfully the script will run to completion with no errors and you'll have copied files from the source to one or many destinations.  You'll have scanned for viruses, created a file list that can be [navigated in this web app](http://wgbh.github.io/preservation-workflow/), generated text files to verify copied files are identical to the source files and created FITS technical metadata xml for all the source files.
