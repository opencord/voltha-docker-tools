# -*- dockerfile -*-
# -----------------------------------------------------------------------
# Copyright 2020-2024 Open Networking Foundation Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# -----------------------------------------------------------------------
# SPDX-FileCopyrightText: 2020-2024 Open Networking Foundation Contributors
# SPDX-License-Identifier: Apache-2.0
# -----------------------------------------------------------------------
# Intent:
# -----------------------------------------------------------------------

ARG GOLANG_VERSION
FROM golang:$GOLANG_VERSION-alpine3.13 as go-build

ARG PROTOC_VERSION
ARG PROTOC_SHA256SUM
ARG PROTOC_GEN_GO_VERSION
ARG PROTOC_GEN_GRPC_GATEWAY_VERSION

RUN apk add --no-cache libatomic=10.2.1_pre1-r3 musl=1.2.2-r0

# download & compile this specific version of protoc-gen-go
RUN GO111MODULE=on CGO_ENABLED=0 go get -a -u \
    github.com/golang/protobuf/protoc-gen-go@v$PROTOC_GEN_GO_VERSION \
    github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway@v$PROTOC_GEN_GRPC_GATEWAY_VERSION \
    github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger@v$PROTOC_GEN_GRPC_GATEWAY_VERSION

RUN mkdir -p /tmp/protoc3 && \
    wget -O /tmp/protoc-${PROTOC_VERSION}-linux-x86_64.zip https://github.com/google/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip && \
    [ "$(sha256sum /tmp/protoc-${PROTOC_VERSION}-linux-x86_64.zip)" = "${PROTOC_SHA256SUM}  /tmp/protoc-${PROTOC_VERSION}-linux-x86_64.zip" ] && \
    unzip /tmp/protoc-${PROTOC_VERSION}-linux-x86_64.zip -d /tmp/protoc3 && \
    chmod -R a+rx /tmp/protoc3/

ARG GOLANG_VERSION
FROM golang:$GOLANG_VERSION-alpine3.13 as cpp-build

ARG PROTOC_GEN_CPP_VERSION

# Install required packages
RUN apk add --no-cache \
    build-base=0.5-r3 \
    git=2.30.2-r0 \
    cmake=3.18.4-r1 \
    linux-headers=5.7.8-r0 \
    perl=5.32.0-r0

WORKDIR /src

# Clone grpc and submodules
RUN git clone --recurse-submodules -b v${PROTOC_GEN_CPP_VERSION} \
        --depth=1 --shallow-submodules https://github.com/grpc/grpc

# Create and configure make environment
RUN mkdir -p /src/grpc/cmake/build
WORKDIR /src/grpc/cmake/build
RUN cmake \
        -DgRPC_INSTALL=ON \
        -DCMAKE_INSTALL_PREFIX=/install \
        -DCMAKE_BUILD_TYPE=Release \
        -DgRPC_ABSL_PROVIDER=module \
        -DgRPC_CARES_PROVIDER=module \
        -DgRPC_PROTOBUF_PROVIDER=module \
        -DgRPC_RE2_PROVIDER=module \
        -DgRPC_SSL_PROVIDER=module \
        -DgRPC_ZLIB_PROVIDER=module \
        ../..

# Build the cpp plugin
RUN make grpc_cpp_plugin

FROM busybox:1.31.1-glibc

# dynamic libs for protoc
COPY --from=go-build /usr/lib/libatomic.so.1 /usr/lib/
COPY --from=go-build /lib/libc.musl-x86_64.so.1 /usr/lib/
COPY --from=cpp-build /usr/lib/libstdc++.so.6 /usr/lib/
COPY --from=cpp-build /usr/lib/libgcc_s.so.1 /usr/lib/
COPY --from=cpp-build /lib/ld-musl-x86_64.so.1 /usr/lib/
COPY --from=cpp-build /lib/ld-musl-x86_64.so.1 /lib/

ENV LD_LIBRARY_PATH=/usr/lib

# protoc & well-known-type definitions
COPY --from=go-build /tmp/protoc3/bin/* /usr/local/bin/
COPY --from=go-build /tmp/protoc3/include/ /usr/local/include/

# copy protoc-gen-go, protoc-gen-grpc-gateway, protoc-gen-swagger,
# and grpc_cpp_plugin
COPY --from=go-build /go/bin/* /usr/local/bin/
COPY --from=cpp-build /src/grpc/cmake/build/grpc_cpp_plugin /usr/local/bin

WORKDIR /app

# Label image
ARG org_label_schema_version=unknown
ARG org_label_schema_vcs_url=unknown
ARG org_label_schema_vcs_ref=unknown
ARG org_label_schema_build_date=unknown
ARG org_opencord_vcs_commit_date=unknown
ARG org_opencord_vcs_dirty=unknown
ARG PROTOC_VERSION=unknown
ARG PROTOC_GEN_GO_VERSION=unknown
ARG PROTOC_GEN_GRPC_GATEWAY_VERSION=unknown

LABEL org.label-schema.schema-version=1.0 \
      org.label-schema.name=voltha-protoc \
      org.label-schema.version=$org_label_schema_version \
      org.label-schema.vcs-url=$org_label_schema_vcs_url \
      org.label-schema.vcs-ref=$org_label_schema_vcs_ref \
      org.label-schema.build-date=$org_label_schema_build_date \
      org.opencord.vcs-commit-date=$org_opencord_vcs_commit_date \
      org.opencord.vcs-dirty=$org_opencord_vcs_dirty \
      org.opencord.protoc-version=$PROTOC_VERSION \
      org.opencord.protoc-gen-go-version=$PROTOC_GEN_GO_VERSION \
      org.opencord.protoc-gen-grpc-gateway-version=$PROTOC_GEN_GRPC_GATEWAY_VERSION

# [EOF]
