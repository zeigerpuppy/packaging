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
    echo "$0: build type required" >&2
    exit $badusage
fi

buildtype=$1

name=`git config --get user.name`
email=`git config --get user.email`
packager="${name} <${email}>"

mkdir -p ${packagesdir}

while read line; do
    IFS=',' read os release <<< "$line"

    outputdir="${packagesdir}/${os}-${release}"
    mkdir -p "${outputdir}"

    if [[ "${os}" = 'debian' ]] || [[ "${os}" = 'ubuntu' ]]; then
        docker run --rm -v ${outputdir}:/packages -e "GITHUB_TOKEN=${GITHUB_TOKEN}" -e "DEBFULLNAME=${name}" -e "DEBEMAIL=${email}" citusdata/buildbox-${os}:${release} citus "$buildtype"
    elif [[ "${os}" = 'centos' ]] || [[ "${os}" = 'fedora' ]] || [[ "${os}" = 'oraclelinux' ]]; then
        # redhat variants need to build each PostgreSQL version separately
        IFS=' '
        for pgversion in ${pgversions}; do
            pgshort=${pgversion//./}
            docker run --rm -v ${outputdir}:/packages -e "GITHUB_TOKEN=${GITHUB_TOKEN}" -e "RPM_PACKAGER=${packager}" citusdata/buildbox-${os}-${pgshort}:${release} citus "$buildtype"
        done
    else
        echo "$0: unrecognized OS -- ${os}" >&2
        exit $badusage
    fi
done <${topdir}/os-list.csv
