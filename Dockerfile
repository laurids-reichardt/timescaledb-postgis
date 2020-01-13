FROM timescale/timescaledb:1.5.1-pg11

ARG POSTGIS_VERSION
ENV POSTGIS_VERSION ${POSTGIS_VERSION:-2.5.3}

RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.11/main" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.11/community" >> /etc/apk/repositories && \
    apk update && \
    set -ex \
    && apk add --no-cache --virtual .fetch-deps \
                ca-certificates \
                openssl \
                tar \
    # add libcrypto from (edge:main) for gdal-2.3.0
    && apk add --no-cache --virtual .crypto-rundeps \
                --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
                libressl2.7-libcrypto \
                libcrypto1.1 \
    && apk add --no-cache --virtual .postgis-deps --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
        geos \
        gdal \
        proj \
        protobuf-c \
    && apk add --no-cache --virtual .build-deps --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
        postgresql-dev \
        perl \
        file \
        geos-dev \
        libxml2-dev \
        gdal-dev \
        proj-dev \
        protobuf-c-dev \
        json-c-dev \
        gcc g++ \
        make \
    && cd /tmp \
    && wget http://download.osgeo.org/postgis/source/postgis-${POSTGIS_VERSION}.tar.gz -O - | tar -xz \
    && chown root:root -R postgis-${POSTGIS_VERSION} \
    && cd /tmp/postgis-${POSTGIS_VERSION} \
    && ./configure \
    && echo "PERL = /usr/bin/perl" >> extensions/postgis/Makefile \
    && echo "PERL = /usr/bin/perl" >> extensions/postgis_topology/Makefile \
    && make -s \
    && make -s install \
    && apk add --no-cache --virtual .postgis-rundeps \
        json-c \
    && cd / \
    \
    && rm -rf /tmp/postgis-${POSTGIS_VERSION} \
    && apk del .fetch-deps .build-deps