set -ex

rm -rf tmp
mkdir -p tmp/output

# The script modifies files in place, but we do not want to touch the fixtures.
cp -a spec/fixtures/example-good/input tmp/input

CI=true bash ./preserve.sh tmp/input tmp/output/metadata tmp/output/dest-1 tmp/output/dest-2
diff -qr spec/fixtures/example-good/output tmp/output
