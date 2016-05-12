# vim:set ft=dockerfile:
FROM fedora:23

# install build tools and PostgreSQL development files
RUN yum -y update \
    && yum groupinstall -y 'Development Tools' \
    && yum install -y \
        curl \
        flex \
        libxml2-devel \
        libxslt-devel \
        openssl-devel \
        pam-devel \
        readline-devel \
        rpm-build \
        spectool \
        tar \
    && yum install -y https://download.postgresql.org/pub/repos/yum/9.4/fedora/fedora-23-x86_64/pgdg-fedora94-9.4-4.noarch.rpm \
    && yum install -y postgresql94-devel \
    && yum clean all

# install jq to process JSON API responses
RUN curl -sL https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 \
         -o /usr/bin/jq \
    && chmod +x /usr/bin/jq

# install latest Citus release to get header files
RUN curl -s https://packagecloud.io/install/repositories/citusdata/community/script.rpm.sh | bash \
    && yum install -y citus_94 \
    && yum clean all

# set PostgreSQL version, place scripts on path, and declare output volume
ENV PGVERSION=9.4 \
    PATH=/scripts:$PATH
COPY scripts /scripts
VOLUME /packages

ENTRYPOINT ["/scripts/fetch_and_build_rpm"]
