#!/bin/bash

# make bash behave
set -euo pipefail
IFS=$'\n\t'

pgversions='9.4 9.5'
topdir=`pwd`
dockerfiles_dir="${topdir}/dockerfiles"
templates_dir="${topdir}"/templates

while read line; do
    IFS=',' read os release <<< "$line"

    sed_cmd='s/%%os%%/'"${os}"'/g; s/%%release%%/'"${release}"'/g'

    if [[ "${os}" = 'debian' ]] || [[ "${os}" = 'ubuntu' ]]; then
        # debian variants have a single Dockerfile
        target_subdir="${dockerfiles_dir}/${os}/${release}"
        mkdir -p ${target_subdir}

        template="${templates_dir}"/Dockerfile-deb.tmpl
        sed 's/%%os%%/'"${os}"'/g; s/%%release%%/'"${release}"'/g' ${template} > ${target_subdir}/Dockerfile
    elif [[ "${os}" = 'centos' ]] || [[ "${os}" = 'fedora' ]]; then
        # redhat variants need a base Dockerfile...
        target_subdir="${dockerfiles_dir}/${os}-base/${release}"
        mkdir -p ${target_subdir}

        template="${templates_dir}"/Dockerfile-rpm-base.tmpl
        sed 's/%%os%%/'"${os}"'/g; s/%%release%%/'"${release}"'/g' ${template} > ${target_subdir}/Dockerfile

        # and a child Dockerfile for each PostgreSQL version
        IFS=' '
        for pgversion in ${pgversions}; do
            pgshort=${pgversion//./}
            target_subdir="${dockerfiles_dir}/${os}-${pgshort}/${release}"
            mkdir -p ${target_subdir}

            template="${templates_dir}"/Dockerfile-rpm-child.tmpl
            sed "$sed_cmd; s/%%pgversion%%/${pgversion}/g" ${template} > ${target_subdir}/Dockerfile
        done
    fi
done <${topdir}/os-list.csv
