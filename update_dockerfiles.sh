#!/bin/bash

# make bash behave
set -euo pipefail
IFS=$'\n\t'

pgversions='9.4 9.5'
topdir=`pwd`
dockerfiles_dir="${topdir}/dockerfiles"
templates_dir="${topdir}"/templates

badusage=64

function update_rpm_dockerfile {
    os=$1
    release=$2
    pgversion=$3

    pgshort=${pgversion//./}
    target_subdir="${dockerfiles_dir}/${os}-${pgshort}/${release}"

    dl_prefix="download.postgresql.org/pub/repos/yum/${pgversion}"
    file_pattern="^pgdg-${os}${pgshort}-${pgversion}.*rpm"

    if [[ "${os}" = 'centos' ]] || [[ "${os}" = 'oraclelinux' ]]; then
        rpms_url="${dl_prefix}/redhat/rhel-${release}-x86_64/"
    elif [[ "${os}" = 'fedora' ]]; then
        rpms_url="${dl_prefix}/fedora/fedora-${release}-x86_64/"
    else
        echo "$0: unrecognized OS -- ${os}" >&2
        exit $badusage
    fi

    rpm=`curl -s -l --ftp-ssl "ftp://${rpms_url}" | egrep "$file_pattern" | sort -t'-' -k4 -nr | head -n1`
    rpm_url=${rpms_url}${rpm}

    mkdir -p ${target_subdir}

    template="${templates_dir}"/Dockerfile-rpm.tmpl
    sed "$sed_cmd; s#%%rpm_url%%#${rpm_url}#g; s/%%pgshort%%/${pgshort}/g; s/%%pgversion%%/${pgversion}/g" ${template} > ${target_subdir}/Dockerfile
}

while read line; do
    IFS=',' read os release <<< "$line"

    sed_cmd='s/%%os%%/'"${os}"'/g; s/%%release%%/'"${release}"'/g'

    if [[ "${os}" = 'debian' ]] || [[ "${os}" = 'ubuntu' ]]; then
        # debian variants have a single Dockerfile
        target_subdir="${dockerfiles_dir}/${os}/${release}"
        mkdir -p ${target_subdir}

        template="${templates_dir}"/Dockerfile-deb.tmpl
        sed 's/%%os%%/'"${os}"'/g; s/%%release%%/'"${release}"'/g' ${template} > ${target_subdir}/Dockerfile
    elif [[ "${os}" = 'centos' ]] || [[ "${os}" = 'fedora' ]] || [[ "${os}" = 'oraclelinux' ]]; then
        # redhat variants need a Dockerfile for each PostgreSQL version
        IFS=' '
        for pgversion in ${pgversions}; do
            update_rpm_dockerfile ${os} ${release} ${pgversion}
        done
    else
        echo "$0: unrecognized OS -- ${os}" >&2
        exit $badusage
    fi
done <${topdir}/os-list.csv
