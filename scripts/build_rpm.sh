#!/bin/bash

# make bash behave
set -euo pipefail
IFS=$'\n\t'

timestamp=`date +'%Y%m%d'`
rpm_version=${upcoming}
rpm_release="0.0.pre.${timestamp}.${gitsha:0:7}"

# it's impossible to put prerelease portions of our version tag into
# the rpm version (i.e. "-rc.2"). So for e.g. 5.0.0-rc.<n>, we set the
# rpm version to 5.0.0 and the release to 0.<n>.rc.<n>.
# IFS='-' read rpm_version prerelease_version <<< "${package_version}"
# if [ -n "${prerelease_version}" ]; then
#     rc_version=${prerelease_version/rc./}
#     rpm_release="0.${rc_version}.${prerelease_version}"
# else
#     # stable releases just have the rpm release set to 1
#     rpm_release="1"
# fi

export_dest=/packages/${OS}/${RELEASE}

mkdir /citus-rpm-build && cd /citus-rpm-build

pwd=`pwd`

cp /citus.spec .

spectool -d "gitsha ${gitsha}" -g citus.spec

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
