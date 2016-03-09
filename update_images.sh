#!/bin/bash

# make bash behave
set -euo pipefail
IFS=$'\n\t'

pgversions='9.4 9.5'
topdir=`pwd`
dockerfiles_dir="${topdir}/dockerfiles"

while read line; do
    IFS=',' read os release <<< "$line"

    if [[ "${os}" = 'debian' ]] || [[ "${os}" = 'ubuntu' ]]; then
        docker build -t citusdata/buildbox-${os}:${release} -f dockerfiles/${os}/${release}/Dockerfile .
    elif [[ "${os}" = 'centos' ]] || [[ "${os}" = 'fedora' ]]; then
        # redhat variants need a base image...
        docker build -t citusdata/buildbox-${os}-base:${release} -f dockerfiles/${os}-base/${release}/Dockerfile .

        # and a child image for each PostgreSQL version
        IFS=' '
        for pgversion in ${pgversions}; do
            pgshort=${pgversion//./}
            docker build -t citusdata/buildbox-${os}-${pgshort}:${release} -f dockerfiles/${os}-${pgshort}/${release}/Dockerfile .
        done
    fi
done <${topdir}/os-list.csv
