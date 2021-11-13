#!/bin/bash
set -e

if [ $# -ne 1 ] ; then
    echo "Usage: $0 x.y.z"
    echo "Where x.y.z is the CMake version to build and release."
    echo "An optional suffix starting with a hyphen (e.g. -rc1)"
    echo "can be appended."
    exit 1
fi
cmakeVersion=$1
track=$( echo ${cmakeVersion} | sed 's/^\([0-9]\+\.[0-9]\+\)\.[0-9]\+\(-.\+\)\?$/\1/' )

echo "Building CMake ${cmakeVersion} for track ${track}"

sed -i "s/source-\(branch\|tag\):.*/source-tag: v${cmakeVersion}/" snap/snapcraft.yaml

archesCore20=amd64,arm64,armhf,ppc64el,s390x
archesCore18=i386

sed -i "s/base:.*/base: core20/" snap/snapcraft.yaml
snapcraft remote-build --build-on=${archesCore20} --launchpad-accept-public-upload
sed -i "s/base:.*/base: core18/" snap/snapcraft.yaml
snapcraft remote-build --build-on=${archesCore18} --launchpad-accept-public-upload

tar zcf cmake_${cmakeVersion}_logs.tar.gz cmake_*.txt

# Uploads can take a while, do them in parallel
archesComma=${archesCore20},${archesCore18}
archesSpaced=$(echo ${archesComma} | sed "s/,/ /g")
for arch in ${archesSpaced} ; do
    filename=cmake_${cmakeVersion}_${arch}.snap
    echo "Uploading ${filename} to channel ${track}/edge"
    snapcraft upload ${filename} --release ${track}/edge &
done
wait

echo "All upload jobs finished"
