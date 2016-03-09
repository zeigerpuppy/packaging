#!/bin/bash

# make bash behave
set -euo pipefail
IFS=$'\n\t'

gh_version="5.0.0-rc.2"
gh_tag="3039a584ad78c6f843c079484f9e6dfbddf65087"
deb_version=${gh_version//'-'/'~'}

tarball="citus_${deb_version}.orig.tar.gz"
download="https://api.github.com/repos/citusdata/citus/tarball/${gh_tag}?access_token=${GITHUB_TOKEN}"

export_dest=/packages/${OS}/${RELEASE}

mkdir /build && cd /build

wget -O ${tarball} ${download}

mkdir ${deb_version} && tar xf ${tarball} -C ${deb_version} --strip-components 1

cp -R /debian ${deb_version}/debian

cd ${deb_version} && pg_buildext updatecontrol && debuild -uc -us -sa

mkdir -p ${export_dest}
cp ../*.deb ${export_dest}
