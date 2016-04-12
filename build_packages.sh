#!/bin/bash

# make bash behave
set -euo pipefail
IFS=$'\n\t'

pgversions='9.4 9.5'
upcoming='5.1.0'
topdir=`pwd`
packagesdir=${topdir}/packages
badusage=64

if [ "$#" -ne 1 ]; then
    echo "$0: git commit sha required" >&2
    exit $badusage
fi

gitsha=$1

name=`git config --get user.name`
email=`git config --get user.email`

mkdir -p ${packagesdir}

while read line; do
    IFS=',' read os release <<< "$line"

    if [[ "${os}" = 'debian' ]] || [[ "${os}" = 'ubuntu' ]]; then
        docker run --rm -v ${packagesdir}:/packages -e "DEBFULLNAME=${name}" -e "DEBEMAIL=${email}" -e "upcoming=${upcoming}" -e "gitsha=${gitsha}" citusdata/buildbox-${os}:${release}
    elif [[ "${os}" = 'centos' ]] || [[ "${os}" = 'fedora' ]] || [[ "${os}" = 'oraclelinux' ]]; then
        # redhat variants need to build each PostgreSQL version separately
        IFS=' '
        for pgversion in ${pgversions}; do
            pgshort=${pgversion//./}
            docker run --rm -v ${packagesdir}:/packages -e "upcoming=${upcoming}" -e "gitsha=${gitsha}" citusdata/buildbox-${os}-${pgshort}:${release}
        done
    else
        echo "$0: unrecognized OS -- ${os}" >&2
        exit $badusage
    fi
done <${topdir}/os-list.csv
