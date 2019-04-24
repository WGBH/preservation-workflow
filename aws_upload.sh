#!/bin/bash

IFS=$'\n';

echo "Drag and drop the high-level folder that you would like to upload to s3"
read dir


dir=$(printf %s "$dir" | cut -c1-$[$(printf %s "$dir" | wc -c | awk '{print $1}')-1])

echo "Enter the name of the bucket that you are uploading these files to"
read bucket

echo "Enter the name of the AWS profile you use to access WGBH S3 (if default, enter 'default')"
read profile

echo "Drag and drop the folder where you would like to place the documentation"
read docs


docs=$(printf %s "$docs" | cut -c1-$[$(printf %s "$docs" | wc -c | awk '{print $1}')-1])


errfile="$docs/errors.txt"

if aws --no-verify-ssl --endpoint-url 'http://s3-bos.wgbh.org' s3api list-buckets | grep "$bucket"
then
	echo "bucket exists"
else
	echo "creating bucket"
	aws --no-verify-ssl --endpoint-url 'http://s3-bos.wgbh.org' s3api create-bucket --bucket "$bucket" 2>> "$errfile"
fi

filelist=$(aws --no-verify-ssl --endpoint-url 'http://s3-bos.wgbh.org' s3api list-objects --bucket "$bucket" --query 'Contents[].Key')

cd $dir
for f in $(find "$docs/fits" \( ! -regex '.*/\..*' \) ! -path . -maxdepth 1 -type f -name '*.fits.xml.txt' -exec /bin/bash -l -c 'foo="{}";md5=$(xpath "$foo" "/fits/fileinfo/md5checksum/text()" 2>/dev/null); size=$(xpath "$foo" "/fits/fileinfo/size/text()" 2>/dev/null);path=$(xpath "$foo" "/fits/fileinfo/filepath/text()" 2>/dev/null);echo "$md5"\|"$size"\|"$path"\|"$foo"'  \; ) 
do
	fits=$(echo "$f" | cut -d '|' -f 4)
	path=$(echo "$f" | cut -d '|' -f 3)
	echo "path is $path"
	key="${path#"$dir/"}"
	echo "key is $key" 
	md5=$(echo "$f" | cut -d '|' -f 1)
	echo "md5 is $md5"
	base64md5=$( (echo 0:; echo $md5) | xxd -rp -l 16|base64)
	echo "base64md5 is $base64md5"
	if [ -z "$(echo "$filelist" | grep "$key")" ]
	then 
		aws --no-verify-ssl --profile "$profile" --endpoint-url 'http://s3-bos.wgbh.org' s3api put-object --bucket "$bucket" --key "$key" --content-md5 "$base64md5" --metadata md5="$md5" --body "$path" 2>> "$errfile"
		objectdata=$(aws --no-verify-ssl --endpoint-url 'http://s3-bos.wgbh.org' s3api head-object --bucket "$bucket" --key "$key" | jq -r '[.ContentLength,.ETag]|@tsv' | tr -d '[[:punct:]]')
		etag=$(echo "$objectdata" | cut -f2)
		if [ ! -z "$(echo "$etag" | grep '-')" ]
		then
			size=$(echo "$f" | cut -d '|' -f 2)
			contentLength=$(echo "$objectdata" | cut -f1)
			if [ "$size" == "$contentLength" ] 
			then 
				echo "$key was successfully uploaded to bucket $bucket (file size match)" >> "$docs"/ObjectStore_inventory.txt
				sed -i '' -e "s#\<\?.*\?\>#&\<\!DOCTYPE fits \[\<\!ENTITY wgbh-s3-location 'http://s3-bos.wgbh.org/$bucket/$key'\>\]\>#1"  "$fits" 2>> "$errfile"
			else 
				echo "$key was not successfully uploaded (file size mismatch)" >> "$errfile"
			fi
		else
			if [ "$etag" == "$md5" ]
			then
				echo "$key was successfully uploaded to bucket $bucket (ETag matches md5)" >> "$docs"/ObjectStore_inventory.txt
				sed -i '' -e "s#\<\?.*\?\>#&\<\!DOCTYPE fits \[\<\!ENTITY wgbh-s3-location 'http://s3-bos.wgbh.org/$bucket/$key'\>\]\>#1"  "$fits" 2>> "$errfile"
			else
				echo "$key was not successfully uploaded (md5 mismatch)" >> "$errfile"
			fi
 		fi
 	else
 		echo "$key was not successfully uploaded (potential key collision)" >> "$errfile"
 	fi
done

cd "$docs/fits"
xfits=$(find . -type f -exec grep -L wgbh-s3-location {} \;)
if [ ! -z "$(echo "$xfits")" ]
then
	echo "check $xfits" >> "$errfile"
else
	zip -jr "$docs/fits.zip" "$docs/fits"
fi
	
unset IFS
