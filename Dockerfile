# ======================================================================
# Dockerfile to compile wgrib2 based on Alpine linux
#
#           Homepage: http://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/
# Available versions: ftp://ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/
# ======================================================================

FROM area51/alpine-dev AS base
ARG version

ENV FILE_TYPE ""
ENV LINK_FILE_TO_DOWNLOAD ""
ENV GRIB_PARAMS ""
ENV ROUTING_KEY_PARSE_PREFIX ""
ENV GRIB_POSITION ""
ENV OTHER ""
ENV DEBUG true

ENV CC=gcc
ENV FC=gfortran

RUN apk add --no-cache \
      zlib-dev

RUN wget -q -O /tmp/wgrib2.tgz \
      ftp://ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz.v${version}

RUN mkdir -p /opt && \
    cd /opt/ && \
    tar -xf /tmp/wgrib2.tgz

RUN cd /opt/grib2 && \
    make

# ======================================================================
# The final image with alpine & just wgrib2 installed
FROM alpine

RUN apk add --no-cache \
      ca-certificates \
      curl \
      libgfortran \
      libgomp

COPY --from=base /opt/grib2/wgrib2/wgrib2 /usr/local/bin/wgrib2

WORKDIR /opt/
