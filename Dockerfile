# syntax=docker/dockerfile:1
# NOTE Lint this file with https://hadolint.github.io/hadolint/

# SPDX-FileCopyrightText: 2022-2025 Robin Vobruba <hoijui.quaero@gmail.com>
#
# SPDX-License-Identifier: Unlicense

# NOTE This uses a horribly outdated base image (from 2020),
#      resulting in all kinds of bugs and other issues.
#FROM nimlang/nim:2.2.4-ubuntu-regular
# NOTE Similar to above.
#FROM nimlang/choosenim:latest
# ... so we just craft our own:
FROM bitnami/minideb:latest

# Set parameters like so:
# docker build \
#     --build-arg reuse_tool_release="5.0.2" \
#     --build-arg okh_tool_bin="build/okh-tool" \
#     .
ARG reuse_tool_release=5.0.2
ARG okh_tool_release=2.4.2
ARG okh_tool_bin=okh-tool
ARG repvar_release=0.14.2
ARG projvar_release=0.19.9
ARG mle_release=0.26.1
ARG mlc_release=0.17.1
ARG obadgen_release=0.2.3
ARG osh_dir_std_release=0.8.4

# Installs the FSF REUSE CLI tool
# NOTE This is a bug-fix/hack to ensure installation of dependency 'tzdata'
#      to pass non-interactively; see:
#      https://stackoverflow.com/a/58264927/586229
ENV DEBIAN_FRONTEND=noninteractive

RUN \
    install_packages \
        bc \
        ca-certificates \
        curl \
        libpcre3-dev \
        libssl-dev \
        gcc \
        git \
        jq \
        mercurial \
        openssl \
        pandoc \
        python3 \
        python3-pip \
        reuse \
        rubygems \
        ruby-mdl \
        wget \
        xz-utils

# Install latest stable Nim, using choosenim
RUN \
    wget -qO - https://nim-lang.org/choosenim/init.sh \
        > choosenim_init.sh ; \
    chmod +x choosenim_init.sh ; \
    bash -x ./choosenim_init.sh -y ; \
    rm ./choosenim_init.sh

# Ensure nim and nimble are in PATH
ENV HOME="/root"
ENV PATH="${PATH}:${HOME}/.nimble/bin"

RUN mkdir /osh-tool
WORKDIR /osh-tool

# Copy the `osh` binary if it exists,
# otherwise downloads and extracts it.
# NOTE We use a benign HACK here,
#      COPY-ing:
#          * a glob-for-our-binary (build/okh-tool), and
#          * a file-that-always-exists (config.nims),
#      to be able to conditionally COPY the binary,
#      only if it exists.
#      Note however, that if the *dir* of the binary does not exist,
#      this *will* fail the docker build,
#      and thus we refer to the CWD by default,
#      but allow to overwrite this variable (okh_tool_bin);
#      see the start of the file for how to.
COPY "$okh_tool_bin"* config.nims ./
ENV OKH_TOOL_PKG="okh-tool-$okh_tool_release-x86_64-unknown-linux-musl"
ENV OKH_TOOL_DL="https://github.com/OPEN-NEXT/LOSH-OKH-tool/releases/download/$okh_tool_release/$OKH_TOOL_PKG.tar.gz"
RUN rm config.nims && \
    if ! [ -f okh-tool ] ; \
    then \
        wget --quiet "$OKH_TOOL_DL" && \
        tar xf $OKH_TOOL_PKG.tar.gz && \
        mv $OKH_TOOL_PKG/okh-tool ./ && \
        rm $OKH_TOOL_PKG.tar.gz && \
        rm -Rf $OKH_TOOL_PKG ; \
    fi

ENV REPVAR_PKG="repvar-${repvar_release}-x86_64-unknown-linux-musl"
ENV REPVAR_DL="https://github.com/hoijui/repvar/releases/download/$repvar_release/$REPVAR_PKG.tar.gz"
RUN wget --quiet "$REPVAR_DL" && \
    tar xf $REPVAR_PKG.tar.gz && \
    mv $REPVAR_PKG/repvar ./ && \
    rm $REPVAR_PKG.tar.gz && \
    rm -Rf $REPVAR_PKG

ENV PROJVAR_PKG="projvar-${projvar_release}-x86_64-unknown-linux-musl"
ENV PROJVAR_DL="https://github.com/hoijui/projvar/releases/download/$projvar_release/$PROJVAR_PKG.tar.gz"
RUN wget --quiet "$PROJVAR_DL" && \
    tar xf $PROJVAR_PKG.tar.gz && \
    mv $PROJVAR_PKG/projvar ./ && \
    rm $PROJVAR_PKG.tar.gz && \
    rm -Rf $PROJVAR_PKG

ENV MLE_PKG="mle-${mle_release}-x86_64-unknown-linux-musl"
ENV MLE_DL="https://github.com/hoijui/mle/releases/download/$mle_release/$MLE_PKG.tar.gz"
RUN wget --quiet "$MLE_DL" && \
    tar xf $MLE_PKG.tar.gz && \
    mv $MLE_PKG/mle ./ && \
    rm $MLE_PKG.tar.gz && \
    rm -Rf $MLE_PKG

ENV MLC_PKG="mlc-${mlc_release}-x86_64-unknown-linux-musl"
ENV MLC_DL="https://github.com/hoijui/mlc/releases/download/$mlc_release/$MLC_PKG.tar.gz"
RUN wget --quiet "$MLC_DL" && \
    tar xf $MLC_PKG.tar.gz && \
    mv $MLC_PKG/mlc ./ && \
    rm $MLC_PKG.tar.gz && \
    rm -Rf $MLC_PKG

ENV OBADGEN_PKG="obadgen-${obadgen_release}-x86_64-unknown-linux-musl"
ENV OBADGEN_DL="https://github.com/hoijui/obadgen/releases/download/$obadgen_release/$OBADGEN_PKG.tar.gz"
RUN wget --quiet "$OBADGEN_DL" && \
    tar xf $OBADGEN_PKG.tar.gz && \
    mv $OBADGEN_PKG/obadgen ./ && \
    rm $OBADGEN_PKG.tar.gz && \
    rm -Rf $OBADGEN_PKG

ENV OSH_DIR_STD_PKG="osh-dir-std-rs-${osh_dir_std_release}-x86_64-unknown-linux-musl"
ENV OSH_DIR_STD_DL="https://github.com/hoijui/osh-dir-std-rs/releases/download/$osh_dir_std_release/$OSH_DIR_STD_PKG.tar.gz"
RUN wget --quiet "$OSH_DIR_STD_DL" && \
    tar xf $OSH_DIR_STD_PKG.tar.gz && \
    mv $OSH_DIR_STD_PKG/osh-dir-std ./ && \
    rm $OSH_DIR_STD_PKG.tar.gz && \
    rm -Rf $OSH_DIR_STD_PKG

ENV IS_PUB_NAME="is-git-forge-public"
#ENV IS_PUB_CLONE_URL="https://github.com/hoijui/is-git-forge-public.git"
ENV IS_PUB_DL="https://raw.githubusercontent.com/hoijui/is-git-forge-public/master/src/software/$IS_PUB_NAME"
RUN wget --progress=dot:giga "$IS_PUB_DL" && \
    chmod +x "$IS_PUB_NAME"

# Ensures the `osh` tool is in PATH
ENV OSH_TOOL_CLONE_URL="https://github.com/hoijui/osh-tool.git"
RUN \
    # Checkout all the osh-tool sources \
    git clone --recurse-submodules $OSH_TOOL_CLONE_URL sources && \
    cd /osh-tool/sources && \
    git submodule update --init && \
    # Builds the `osh` tool
    nimble -y build && \
    cp build/osh report_gen* ../ && \
    cd ..

# NOTE This fixes a bug; see:
#      https://github.com/actions/runner/issues/2033
RUN git config --global --add safe.directory /github/workspace

ENV PATH="${PATH}:/osh-tool"

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

CMD ["report_gen", "--download-badges"]
