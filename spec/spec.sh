set -ex

mkdir tmp
bash ./preserve.sh spec/fixtures/example-1/source tmp/metadata tmp/dest-1 tmp/dest-2
diff -qr spec/fixtures/example-1/metadata tmp/metadata
diff -qr spec/fixtures/example-1/dest-1   tmp/dest-1
diff -qr spec/fixtures/example-1/dest-2   tmp/dest-2 
