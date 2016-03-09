#!/bin/bash

# make bash behave
set -euo pipefail
IFS=$'\n\t'

gh_version="5.0.0-rc.2"
gh_tag="3039a584ad78c6f843c079484f9e6dfbddf65087"
rpm_version=${gh_version%%-*}
pgmajorversion=${PGVERSION//'.'/}
download="https://api.github.com/repos/citusdata/citus/tarball/${gh_tag}?access_token=${GITHUB_TOKEN}"

export_dest=/packages/${OS}/${RELEASE}

mkdir /citus-rpm-build && cd /citus-rpm-build

pwd=`pwd`

cp /citus.spec .

# TODO: use spectool to download source after public
wget -O ${gh_tag} ${download}

rpmbuild --define "_sourcedir ${pwd}" \
--define "_specdir ${pwd}" \
--define "_builddir ${pwd}" \
--define "_srcrpmdir ${pwd}" \
--define "_rpmdir ${pwd}" \
--define "pginstdir /usr/pgsql-${PGVERSION}" \
--define "pgmajorversion ${pgmajorversion}" \
--define "rpmversion ${rpm_version}" \
--define "ghtag ${gh_tag}" \
-bb citus.spec

mkdir -p ${export_dest}
cp /citus-rpm-build/x86_64/*.rpm ${export_dest}
