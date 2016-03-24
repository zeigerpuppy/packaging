#!/bin/bash

# make bash behave
set -euo pipefail
IFS=$'\n\t'

pgversions='9.4 9.5'
topdir=`pwd`
packagesdir=${topdir}/packages

mkdir -p ${packagesdir}

badusage=64

while read line; do
    IFS=',' read os release <<< "$line"

    if [[ "${os}" = 'debian' ]] || [[ "${os}" = 'ubuntu' ]]; then
        docker run --rm -v ${packagesdir}:/packages citusdata/buildbox-${os}:${release}
    elif [[ "${os}" = 'centos' ]] || [[ "${os}" = 'fedora' ]] || [[ "${os}" = 'oraclelinux' ]]; then
        # redhat variants need to build each PostgreSQL version separately
        IFS=' '
        for pgversion in ${pgversions}; do
            pgshort=${pgversion//./}
            docker run --rm -v ${packagesdir}:/packages citusdata/buildbox-${os}-${pgshort}:${release}
        done
    else
        echo "$0: unrecognized OS -- ${os}" >&2
        exit $badusage
    fi
done <${topdir}/os-list.csv

