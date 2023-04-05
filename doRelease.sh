#!/bin/bash
set -e

# This value is changed on each release branch. For release branches, this value
# should have the form X.Y.Z or X.Y.Z-rcN
cmakeVersion=master

if [ $# -gt 0 ] ; then
    echo "No command line options are supported. The CMake version is"
    echo "hard-coded in this script as \"${cmakeVersion}\""
    exit 1
fi

if [ "${cmakeVersion}" = "master" ] ; then
    track=latest
    cmake_source_version_key=branch
    cmake_source_version_value=master
else
    track=$( echo ${cmakeVersion} | sed -E 's/^([0-9]+\.[0-9]+)\.[0-9]+(-.+)?$/\1/' )
    cmake_source_version_key=tag
    cmake_source_version_value=v${cmakeVersion}
fi

echo "Building CMake ${cmakeVersion} for track ${track}"

archesCore20=amd64,arm64,armhf,ppc64el,s390x
archesCore18=i386

rm -rf build
mkdir -p build/core20
mkdir -p build/core18
cp -a snap build/core20/
cp -a snap build/core18/

platform=$( uname )
if [[ $platform == Darwin ]]; then
  sedInPlace="-i \"\""
else
  sedInPlace=-i
fi

here=$( cd `dirname $0` ; pwd )
cd ${here}/build/core20
sed ${sedInPlace} "s/BASE_FOR_ARCH/core20/" snap/snapcraft.yaml
sed ${sedInPlace} "s/CMAKE_SOURCE_VERSION_KEY/${cmake_source_version_key}/" snap/snapcraft.yaml
sed ${sedInPlace} "s/CMAKE_SOURCE_VERSION_VALUE/${cmake_source_version_value}/" snap/snapcraft.yaml
sed ${sedInPlace} "s+@QHELPGENERATOR_EXECUTABLE@+/usr/bin/qhelpgenerator+" snap/snapcraft.yaml
snapcraft remote-build --build-on=${archesCore20} --launchpad-accept-public-upload
mv cmake_*.snap cmake_*.txt ../

cd ${here}/build/core18
sed ${sedInPlace} "s/BASE_FOR_ARCH/core18/" snap/snapcraft.yaml
sed ${sedInPlace} "s/CMAKE_SOURCE_VERSION_KEY/${cmake_source_version_key}/" snap/snapcraft.yaml
sed ${sedInPlace} "s/CMAKE_SOURCE_VERSION_VALUE/${cmake_source_version_value}/" snap/snapcraft.yaml
sed ${sedInPlace} "s+@QHELPGENERATOR_EXECUTABLE@+/usr/bin/qcollectiongenerator+" snap/snapcraft.yaml
snapcraft remote-build --build-on=${archesCore18} --launchpad-accept-public-upload
mv cmake_*.snap cmake_*.txt ../

cd ${here}/build
tar zcf cmake_${cmakeVersion}_logs.tar.gz cmake_*.txt

# Uploads can take a while. Was previously able to do them in parallel, but that became
# unreliable. Python errors related to retrieving logs began failing. Run them one at a
# time for now until we can safely run parallel again.
for filename in cmake_*.snap ; do
    echo "Uploading ${filename} to channel ${track}/edge"
    snapcraft upload ${filename} --release ${track}/edge # &
done
#wait

echo "All upload jobs finished"
