#!/bin/bash

# make bash behave
set -euo pipefail
IFS=$'\n\t'

pgversions='9.4 9.5'
topdir=$(pwd)
dockerfiles_dir="${topdir}/dockerfiles"

badusage=64

while read -r line; do
    IFS=',' read -r os release <<< "$line"

    if [[ "${os}" = 'debian' ]] || [[ "${os}" = 'ubuntu' ]]; then
        docker build -t "citusdata/buildbox-${os}:${release}" \
                     -f "${dockerfiles_dir}/${os}/${release}/Dockerfile" .
    elif [[ "${os}" = 'centos' ]] || [[ "${os}" = 'fedora' ]] || [[ "${os}" = 'oraclelinux' ]]; then
        # redhat variants need an image for each PostgreSQL version
        IFS=' '
        for pgversion in ${pgversions}; do
            pgshort=${pgversion//./}
            docker build -t "citusdata/buildbox-${os}-${pgshort}:${release}" \
                         -f "${dockerfiles_dir}/${os}-${pgshort}/${release}/Dockerfile" .
        done
    else
        echo "$0: unrecognized OS -- ${os}" >&2
        exit $badusage
    fi
done <"${topdir}/os-list.csv"
