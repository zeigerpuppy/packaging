#!/bin/bash

# make bash behave
set -euo pipefail
IFS=$'\n\t'

timestamp=`date +'%Y%m%d'`
deb_version="${upcoming}~pre.${timestamp}.${gitsha:0:7}"

tarball="citus_${deb_version}.orig.tar.gz"
download="https://github.com/citusdata/citus/archive/${gitsha}.tar.gz"

export_dest=/packages/${OS}/${RELEASE}

mkdir /build && cd /build

wget -O ${tarball} ${download}

mkdir ${deb_version} && tar xf ${tarball} -C ${deb_version} --strip-components 1

cp -R /debian ${deb_version}/debian

cd ${deb_version}

dch -v "${deb_version}-1" -D UNRELEASED -u low "Custom package built from git revision ${gitsha}"

pg_buildext updatecontrol && debuild -uc -us -sa

mkdir -p ${export_dest}
cp ../*.deb ${export_dest}
