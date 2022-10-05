# syntax=docker/dockerfile:1
# NOTE Lint this file with https://hadolint.github.io/hadolint/

# SPDX-FileCopyrightText: 2022 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: Unlicense

FROM nimlang/nim:1.6.4

# Set parameters like so:
# docker build \
#     --build-arg reuse_tool_release="1.0.0" \
#     --build-arg okh_tool_release="0.3.1" \
#     .
ARG reuse_tool_release=1.0.0
ARG okh_tool_release=0.3.1
ARG projvar_release=0.11.0

RUN \
    apt-get update ; \
    apt-get install -y --no-install-recommends \
        git \
        mercurial \
        pandoc \
        python3-pip \
        wget \
        ; \
    rm -rf /var/lib/apt/lists/*
#        libssl-dev \
#        reuse \

# Installs the FSF REUSE CLI tool
# NOTE This is a bug-fix/hack to ensure installation of dependency 'tzdata'
#      to pass non-interactively; see:
#      https://stackoverflow.com/a/58264927/586229
ENV DEBIAN_FRONTEND=noninteractive
RUN pip3 install --user reuse==$reuse_tool_release
ENV HOME="/root"
ENV PATH="${PATH}:${HOME}/.local/bin"

# NOTE Solution from:
# https://www.mail-archive.com/nim-general@lists.nim-lang.org/msg19329.html
#RUN \
#     wget --quiet http://nz2.archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb ; \
#     dpkg -i libssl1.1_*.deb ; \
#     rm /libssl1.1_*.deb

RUN mkdir /osh-tool
WORKDIR /osh-tool

# Copy the `osh` binary if it exists,
# otherwise downloads and extracts it.
# NOTE We use a begning HACK here,
#      COPY-ing:
#          * a glob-for-our-binary (build/okh-tool), and
#          * a file-that-always-exists (config.nims),
#      to be able to conditionally COPY the binary,
#      only if it exists.
COPY build/okh-tool* config.nims ./
ENV OKH_TOOL_PKG="okh-tool-$okh_tool_release-x86_64-unknown-linux-musl"
ENV OKH_TOOL_DL="https://github.com/OPEN-NEXT/LOSH-OKH-tool/releases/download/$okh_tool_release/$OKH_TOOL_PKG.tar.gz"
RUN rm config.nims ; \
    if ! [ -f okh-tool ] ; \
    then \
        wget --quiet "$OKH_TOOL_DL" ; \
        tar xf $OKH_TOOL_PKG.tar.gz ; \
        mv $OKH_TOOL_PKG/okh-tool ./ ; \
        rm $OKH_TOOL_PKG.tar.gz ; \
        rm -Rf $OKH_TOOL_PKG ; \
    fi

ENV PROJVAR_PKG="projvar-${projvar_release}-x86_64-unknown-linux-musl"
ENV PROJVAR_DL="https://github.com/hoijui/projvar/releases/download/$projvar_release/$PROJVAR_PKG.tar.gz"
RUN wget --quiet "$PROJVAR_DL" ; \
    tar xf $PROJVAR_PKG.tar.gz ; \
    mv $PROJVAR_PKG/projvar ./ ; \
    rm $PROJVAR_PKG.tar.gz ; \
    rm -Rf $PROJVAR_PKG

# Ensures the `osh` tool is in PATH
ENV OSH_TOOL_CLONE_URL="https://github.com/hoijui/osh-tool.git"
RUN \
    # Checkout all the osh-tool sources \
    git clone --recurse-submodules $OSH_TOOL_CLONE_URL sources ; \
    cd /osh-tool/sources ; \
    git submodule update --init ; \
    # Builds the `osh` tool
    nimble -y build && cp build/osh ../ ; \
    cd ..

# NOTE This fixes a bug; see:
#      https://github.com/actions/runner/issues/2033
RUN git config --global --add safe.directory /github/workspace

COPY report_gen* /osh-tool/

ENV PATH="${PATH}:/osh-tool"

LABEL org.opencontainers.artifact.description: human readable description for the artifact (string)
LABEL org.opencontainers.image.authors="Robin Vobruba <hoijui.quaero@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/hoijui/osh-tool/blob/master/README.md"
LABEL org.opencontainers.image.source="https://github.com/hoijui/osh-tool/blob/master/Dockerfile"
#    org.opencontainers.image.version version of the packaged software
#        The version MAY match a label or tag in the source code repository
#        version MAY be Semantic versioning-compatible
#    org.opencontainers.image.revision Source control revision identifier for the packaged software.
#    org.opencontainers.image.licenses License(s) under which contained software is distributed as an SPDX License Expression.
LABEL org.opencontainers.image.title="OSH-Tool"
LABEL org.opencontainers.image.description="Contains the OSH Check/Linter CLI tool and all its requirements"

WORKDIR /data

CMD ["report_gen"]
