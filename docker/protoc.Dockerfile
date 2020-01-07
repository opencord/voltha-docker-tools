FROM golang:1.13.5-alpine as build

ARG PROTOC_VERSION
ARG PROTOC_GEN_GO_VERSION
ARG PROTOC_SHA256SUM

RUN apk add --no-cache libatomic=9.2.0-r3 musl=1.1.24-r0

# download & compile this specific version of protoc-gen-go
RUN GO111MODULE=on go get -u github.com/golang/protobuf/protoc-gen-go@v$PROTOC_GEN_GO_VERSION

RUN mkdir -p /tmp/protoc3 && \
    wget -O /tmp/protoc-${PROTOC_VERSION}-linux-x86_64.zip https://github.com/google/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip && \
    [ "$(sha256sum /tmp/protoc-${PROTOC_VERSION}-linux-x86_64.zip)" = "${PROTOC_SHA256SUM}  /tmp/protoc-${PROTOC_VERSION}-linux-x86_64.zip" ] && \
    unzip /tmp/protoc-${PROTOC_VERSION}-linux-x86_64.zip -d /tmp/protoc3


FROM busybox:1.31.1-glibc

# dynamic libs for protoc
COPY --from=build /usr/lib/libatomic.so.1 /usr/lib/
COPY --from=build /lib/libc.musl-x86_64.so.1 /usr/lib/
ENV LD_LIBRARY_PATH=/usr/lib

# protoc & well-known-type definitions
COPY --from=build /tmp/protoc3/bin/* /usr/local/bin/
COPY --from=build /tmp/protoc3/include/ /usr/local/include/
# fix permissions so non-root can use
RUN chmod -R a+rx /usr/local/bin/protoc && \
    chmod -R a+rX /usr/local/include/

# copy protoc-gen-go
COPY --from=build /go/bin/* /usr/local/bin/

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

LABEL org.label-schema.schema-version=1.0 \
      org.label-schema.name=voltha-protoc \
      org.label-schema.version=$org_label_schema_version \
      org.label-schema.vcs-url=$org_label_schema_vcs_url \
      org.label-schema.vcs-ref=$org_label_schema_vcs_ref \
      org.label-schema.build-date=$org_label_schema_build_date \
      org.opencord.vcs-commit-date=$org_opencord_vcs_commit_date \
      org.opencord.vcs-dirty=$org_opencord_vcs_dirty \
      org.opencord.protoc-version=$PROTOC_VERSION \
      org.opencord.protoc-gen-go-version=$PROTOC_GEN_GO_VERSION
