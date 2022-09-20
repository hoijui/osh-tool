# syntax=docker/dockerfile:1
# NOTE Lint this file with https://hadolint.github.io/hadolint/

# SPDX-FileCopyrightText: 2022 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: Unlicense

FROM ubuntu:22.04

RUN apt-get update
RUN apt-get install -y libssl-dev
RUN apt-get install -y wget
# NOTE Solution from:
# https://www.mail-archive.com/nim-general@lists.nim-lang.org/msg19329.html
RUN wget http://nz2.archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
RUN dpkg -i libssl1.1_*.deb

RUN mkdir /osh-tool
WORKDIR /osh-tool

COPY build/osh /osh-tool/

ENV PATH="${PATH}:/osh-tool"

# Set this parameter like so:
# docker build --build-arg okh_tool_release="0.3.1" .
ARG okh_tool_release=0.3.1

ENV OKH_TOOL_PKG="okh-tool-$okh_tool_release-x86_64-unknown-linux-musl"

RUN wget https://github.com/OPEN-NEXT/LOSH-OKH-tool/releases/download/$okh_tool_release/$OKH_TOOL_PKG.tar.gz
RUN tar xf $OKH_TOOL_PKG.tar.gz
RUN mv $OKH_TOOL_PKG/okh-tool ./

RUN apt-get install -y git mercurial

# NOTE This is a bug-fix/hack to ensure installation of dependency 'tzdata'
#      to pass non-interactively; see:
#      https://stackoverflow.com/a/58264927/586229
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y install -y --no-install-recommends reuse
#RUN apt-get install -y python3-pip
#RUN pip3 install --user reuse


#RUN apt-get install -y pipx
#RUN pipx install reuse
#ENV PATH="${PATH}:~/.local/bin"

RUN rm -Rf $OKH_TOOL_PKG
RUN rm $OKH_TOOL_PKG.tar.gz
RUN rm /libssl1.1_*.deb
#RUN rm -rf /var/lib/apt/lists/*

LABEL com.example.version="0.0.1-beta"



    org.opencontainers.artifact.created date and time on which the artifact was built, conforming to RFC 3339.
    org.opencontainers.artifact.description: human readable description for the artifact (string)
    org.opencontainers.image.created date and time on which the image was built, conforming to RFC 3339.
    org.opencontainers.image.authors contact details of the people or organization responsible for the image (freeform string)
    org.opencontainers.image.url URL to find more information on the image (string)
    org.opencontainers.image.documentation URL to get documentation on the image (string)
    org.opencontainers.image.source URL to get source code for building the image (string)
    org.opencontainers.image.version version of the packaged software
        The version MAY match a label or tag in the source code repository
        version MAY be Semantic versioning-compatible
    org.opencontainers.image.revision Source control revision identifier for the packaged software.
    org.opencontainers.image.vendor Name of the distributing entity, organization or individual.
    org.opencontainers.image.licenses License(s) under which contained software is distributed as an SPDX License Expression.
    org.opencontainers.image.title Human-readable title of the image (string)
    org.opencontainers.image.description Human-readable description of the software packaged in the image (string)



WORKDIR /data

CMD ["osh", "check", "--json"]
