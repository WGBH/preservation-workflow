set -ex

rm -rf tmp
mkdir tmp

CI=true bash ./preserve.sh spec/fixtures/example-good/input tmp/metadata tmp/dest-1 tmp/dest-2
diff -qr spec/fixtures/example-good/output tmp
