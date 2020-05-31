#!/bin/bash
set -e

if [ $# -ne 1 ] ; then
    echo "Usage: $0 x.y.z"
    echo "Where x.y.z is the CMake version to build and release" 1>&2
    exit 1
fi
cmakeVersion=$1
track=$( echo ${cmakeVersion} | sed 's/^\([0-9]\+\.[0-9]\+\)\.[0-9]\+$/\1/' )

echo "Building CMake ${cmakeVersion} for track ${track}"

sed -i "s/source-\(branch\|tag\):.*/source-tag: v${cmakeVersion}/" snap/snapcraft.yaml

# The order of these matches the order they are shown in the Releases panel
# of the snap store, so keep it this way for convenience
archesComma=amd64,arm64,armhf,i386,ppc64el,s390x
archesSpaced=$(echo ${archesComma} | sed "s/,/ /g")

snapcraft remote-build --build-on=${archesComma}

tar zcf cmake_${cmakeVersion}_logs.tar.gz cmake_*.txt

for arch in ${archesSpaced} ; do
    filename=cmake_${cmakeVersion}_${arch}.snap
    echo "Uploading ${filename} to channel ${track}/edge"
    snapcraft push ${filename} --release ${track}/edge
done

