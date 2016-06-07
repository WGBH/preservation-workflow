set -ex

LC_ALL=C
trap 'find . | grep -v .git | sort; echo "FAIL!"' ERR

function setup {
    rm -rf tmp
    mkdir -p tmp/output

    # The script modifies files in place, but we do not want to touch the fixtures.
    cp -a $1 tmp/input
}


setup spec/fixtures/example-good/input

# Expect success
CI=true ruby ./preserve.rb tmp/input 'tmp/output/metadata 0' 'tmp/output/dest 1' 'tmp/output/dest 2'
diff --exclude=*.zip -ru spec/fixtures/example-good/output tmp/output


setup spec/fixtures/example-good/input

# Expect non-zero status
! CI=true HOOK='echo "corrupted" > "tmp/output/dest 1/only-in-dest.txt"' \
  ruby ./preserve.rb tmp/input tmp/output/metadata 'tmp/output/dest 1'


setup spec/fixtures/example-good/input

# Expect error message. (Redundant but less confusing than trying to do both at the same time?)
[[ `
    CI=true HOOK='echo "corrupted" > "tmp/output/dest 1/only-in-dest.txt"' \
    ruby ./preserve.rb tmp/input tmp/output/metadata 'tmp/output/dest 1' 2>&1
   ` =~ 'diff not clean' ]] || false
# (Tests by themselves are not trapped, so we need the explicit 'false' at the end.)

echo 'PASS!'
