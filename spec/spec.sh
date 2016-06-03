set -ex

trap 'git status; find . | grep -v .git | sort; echo "FAIL!"' ERR

function setup {
    rm -rf tmp
    mkdir -p tmp/output

    # The script modifies files in place, but we do not want to touch the fixtures.
    cp -a $1 tmp/input
}

setup spec/fixtures/example-good/input

# Expect success
CI=true ruby ./preserve.rb tmp/input tmp/output/metadata tmp/output/dest-1 tmp/output/dest-2
diff --exclude=*.zip -ru spec/fixtures/example-good/output tmp/output

setup spec/fixtures/example-good/input

# Expect failure because of diff
! CI=true HOOK='echo "corrupted" > tmp/output/dest-1/bad_name_for_file.txt' \
  ruby ./preserve.rb tmp/input tmp/output/metadata tmp/output/dest-1 tmp/output/dest-2

echo 'PASS!'
