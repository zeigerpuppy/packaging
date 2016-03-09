#!/bin/bash

# make bash behave
set -euo pipefail
IFS=$'\n\t'

dl_prefix="download.postgresql.org/pub/repos/yum/${PGVERSION}"
pgshort=${PGVERSION//'.'/}
file_pattern="^pgdg-${OS}${pgshort}-${PGVERSION}.*rpm"

badusage=64

case "${OS}" in
    centos)
        rpms_url="${dl_prefix}/redhat/rhel-${RELEASE}-x86_64/"
        ;;
    fedora)
        rpms_url="${dl_prefix}/fedora/fedora-${RELEASE}-x86_64/"
        ;;
    *)
        echo "$0: unrecognized OS -- ${OS}" >&2
        exit $badusage
        ;;
esac

rpm=`curl -l --ftp-ssl "ftp://${rpms_url}" | egrep "$file_pattern" | sort -t'-' -k4 -nr | head -n1`

yum install -y "https://${rpms_url}${rpm}"
yum install -y "postgresql${pgshort}-devel"
yum clean all
