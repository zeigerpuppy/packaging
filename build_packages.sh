#!/bin/bash

# make bash behave
set -euo pipefail
IFS=$'\n\t'

pgversions='9.4 9.5'
topdir=`pwd`
packagesdir=${topdir}/packages

mkdir -p ${packagesdir}

while read line; do
    IFS=',' read os release <<< "$line"

    if [[ "${os}" = 'debian' ]] || [[ "${os}" = 'ubuntu' ]]; then
        docker run --rm -v ${packagesdir}:/packages -e GITHUB_TOKEN citusdata/buildbox-${os}:${release}
    elif [[ "${os}" = 'centos' ]] || [[ "${os}" = 'fedora' ]]; then
        # redhat variants need to build each PostgreSQL version separately
        IFS=' '
        for pgversion in ${pgversions}; do
            pgshort=${pgversion//./}
            docker run --rm -v ${packagesdir}:/packages -e GITHUB_TOKEN citusdata/buildbox-${os}-${pgshort}:${release}
        done
    fi
done <${topdir}/os-list.csv

