# vim:set ft=dockerfile:
FROM centos:7

# FIXME: Hack around docker/docker#10180
RUN ( yum install -y yum-plugin-ovl || yum install -y yum-plugin-ovl ) \
    && yum clean all

# install build tools and PostgreSQL development files
RUN yum groupinstall -y 'Development Tools' \
    && yum install -y \
        curl \
        flex \
        gcc-c++ \
        hunspell-en \
        libxml2-devel \
        libxslt-devel \
        openssl-devel \
        pam-devel \
        readline-devel \
        rpm-build \
        rpmlint \
        spectool \
        tar \
    && yum install -y https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm \
    && yum install -y postgresql96-devel \
    && yum clean all

# install jq to process JSON API responses
RUN curl -sL https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 \
         -o /usr/bin/jq \
    && chmod +x /usr/bin/jq

# install latest Citus release to get header files
# FIXME: Add back after a 9.6-compatible Citus release
# RUN curl -s https://packagecloud.io/install/repositories/citusdata/community/script.rpm.sh | bash \
#     && yum install -y citus_96 \
#     && yum clean all

RUN touch /rpmlintrc \
    && echo '%_build_pkgcheck %{_bindir}/rpmlint -f /rpmlintrc' >> /etc/rpm/macros

# set PostgreSQL version, place scripts on path, and declare output volume
ENV PGVERSION=9.6 \
    PATH=/scripts:$PATH
COPY scripts /scripts
VOLUME /packages

ENTRYPOINT ["/scripts/fetch_and_build_rpm"]
