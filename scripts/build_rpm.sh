#!/bin/bash

# make bash behave
set -euo pipefail
IFS=$'\n\t'

timestamp=`date +'%Y%m%d'`
rpm_version=${upcoming}
rpm_release="0.0.pre.${timestamp}.${gitsha:0:7}"

export_dest=/packages/${OS}/${RELEASE}

mkdir /citus-rpm-build && cd /citus-rpm-build

pwd=`pwd`

cp /citus.spec .

spectool -d "gitsha ${gitsha}" -g citus.spec

rpmdev-bumpspec -c "Custom package built from git revision ${gitsha}" citus.spec

rpmbuild --define "_sourcedir ${pwd}" \
--define "_specdir ${pwd}" \
--define "_builddir ${pwd}" \
--define "_srcrpmdir ${pwd}" \
--define "_rpmdir ${pwd}" \
--define "pginstdir /usr/pgsql-${PGVERSION}" \
--define "pgmajorversion ${PGVERSION//'.'/}" \
--define "rpmversion ${rpm_version}" \
--define "rpmrelease ${rpm_release}" \
--define "gitsha ${gitsha}" \
-bb citus.spec

mkdir -p ${export_dest}
cp /citus-rpm-build/x86_64/*.rpm ${export_dest}
