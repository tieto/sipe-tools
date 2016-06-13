#!/bin/bash

set -e

PROJECT=$1

PKG_BRANCH=pkg-debian-jessie
ORIG_BRANCH=debian-jessie

if [ -z "$PROJECT" ]; then
	echo "Project name not given"
	exit 1
fi

WORKDIR=$(mktemp -d)
if [ -z "$WORKDIR" ]; then
	echo "Couldn't create the work directory"
fi

cd $WORKDIR

if ! wget https://github.com/tieto/$PROJECT/archive/$ORIG_BRANCH.tar.gz; then
	ORIG_BRANCH=launchpad
	wget https://github.com/tieto/$PROJECT/archive/$ORIG_BRANCH.tar.gz
fi
wget https://github.com/tieto/$PROJECT/archive/$PKG_BRANCH.tar.gz

tar xf $PKG_BRANCH.tar.gz $PROJECT-$PKG_BRANCH/debian
rm $PKG_BRANCH.tar.gz

pushd ./$PROJECT-$PKG_BRANCH
SRCNAME=$(dpkg-parsechangelog --show-field Source)
VERSION=$(dpkg-parsechangelog --show-field Version)
DEBVERSION=$VERSION+$(date -u +"%Y%m%d%H%M%S")~debian8

dch -v $DEBVERSION Auto build.
popd

ORIGTAR=${SRCNAME}_$(echo $VERSION | cut -d- -f1).orig.tar.gz

mv $ORIG_BRANCH.tar.gz $ORIGTAR

dpkg-source -b $PROJECT-$PKG_BRANCH

osc checkout home:xhaakon:sipe/$PROJECT -o obs

pushd ./obs
rm -f *.tar.* *.dsc
mv ../*.tar.* ../*.dsc .
osc addremove
osc commit -m "Importing $DEBVERSION"
popd

rm -r $WORKDIR

