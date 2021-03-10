#!/bin/bash

# Adapted from the github action

git clone https://github.com/rorymurdock/git_osx_installer.git
cd git_osx_installer

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

brew install autoconf automake asciidoc docbook xmlto gettext docbook-xsl
export XML_CATALOG_FILES=/usr/local/etc/xml/catalog
make prefix=$HOME all doc info


brew link --force gettext
git clone -n https://github.com/git/git
cd git
#  ALT
GIT_REF="refs/tags/v2.30.2" # Hardcode for now
# GIT_REF="$(git for-each-ref --sort=-taggerdate --count=1 --format='%(refname)' 'refs/tags/v[0-9]*')"
test -n "$GIT_REF" || { echo "No eligible tag found" >&2; exit 1; }
git fetch origin "$GIT_REF"
git switch --detach FETCH_HEAD


cd ../
# set -x # Enable for debugging
PATH=/usr/local/bin:$PATH
make -C git -j$(sysctl -n hw.physicalcpu) GIT-VERSION-FILE dist dist-doc

die () {
  echo "$*" >&2
  exit 1
}

VERSION="`sed -n 's/^GIT_VERSION = //p' <git/GIT-VERSION-FILE`"
test -n "$VERSION" || die "Could not determine version!"
export VERSION

ln -s git git-$VERSION
mkdir -p build
cp git/git-$VERSION.tar.gz git/git-manpages-$VERSION.tar.gz build/ || die "Could not copy .tar.gz files"

# Enable big sur naming
curl -OL https://raw.githubusercontent.com/rorymurdock/git_osx_installer/main/Makefile
# drop the -isysroot `GIT_SDK` hack
sed -i .bak -e 's/ -isysroot .(SDK_PATH)//' Makefile || die "Could not drop the -isysroot hack"
# make sure that .../usr/local/git/share/man/ exists
sed -i .bak -e 's/\(tar .*-C \)\(.*\/share\/man\)$/mkdir -p \2 \&\& &/' Makefile
# For debugging:
#
# cat Makefile
# make vars
PATH=/usr/local/bin:/System/Library/Frameworks:$PATH
make build/intel-universal-snow-leopard/git-$VERSION/osx-built-keychain
PATH=/usr/local/bin:$PATH
make image
mkdir osx-installer
mv *.dmg disk-image/*.pkg osx-installer/
