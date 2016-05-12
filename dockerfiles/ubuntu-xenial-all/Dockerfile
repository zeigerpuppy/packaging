# vim:set ft=dockerfile:
FROM ubuntu:xenial

# install build tools and PostgreSQL development files
RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 \
    && echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        autotools-dev \
        build-essential \
        ca-certificates \
        curl \
        debhelper \
        devscripts \
        fakeroot \
        flex \
        libedit-dev \
        libfile-fcntllock-perl \
        libpam0g-dev \
        libselinux1-dev \
        libxslt-dev \
        lintian \
        postgresql-server-dev-all \
        wget \
    && rm -rf /var/lib/apt/lists/*

# install jq to process JSON API responses
RUN curl -sL https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 \
         -o /usr/bin/jq \
    && chmod +x /usr/bin/jq

# install latest Citus release to get header files
RUN curl -s https://packagecloud.io/install/repositories/citusdata/community/script.deb.sh | bash \
    && apt-get install -y postgresql-9.4-citus postgresql-9.5-citus \
    && rm -rf /var/lib/apt/lists/*

# patch pg_buildext to use multiple processors
COPY make_pg_buildext_parallel.patch /
RUN patch `which pg_buildext` < /make_pg_buildext_parallel.patch

# place scripts on path and declare output volume
ENV PATH /scripts:$PATH
COPY scripts /scripts
VOLUME /packages

ENTRYPOINT ["/scripts/fetch_and_build_deb"]
