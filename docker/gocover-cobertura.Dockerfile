# Copyright 2020-present Open Networking Foundation
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
ARG GOLANG_VERSION
FROM golang:$GOLANG_VERSION-alpine as build

RUN apk add --no-cache build-base=0.5-r3

# download & compile this specific version of gocover-cobertura
ARG GOCOVER_COBERTURA_VERSION
RUN CGO_ENABLED=0 go install -ldflags "-linkmode external -extldflags -static" github.com/t-yuki/gocover-cobertura@$GOCOVER_COBERTURA_VERSION

FROM golang:$GOLANG_VERSION-alpine

# copy gocover-cobertura
COPY --from=build /go/bin/* /usr/local/bin/

WORKDIR /app

ENV GOPATH=/app

RUN mkdir -m 777 /.cache /go/pkg

# Label image
ARG org_label_schema_version=unknown
ARG org_label_schema_vcs_url=unknown
ARG org_label_schema_vcs_ref=unknown
ARG org_label_schema_build_date=unknown
ARG org_opencord_vcs_commit_date=unknown
ARG org_opencord_vcs_dirty=unknown
ARG GOCOVER_COBERTURA_VERSION=unknown

LABEL org.label-schema.schema-version=1.0 \
      org.label-schema.name=voltha-protoc \
      org.label-schema.version=$org_label_schema_version \
      org.label-schema.vcs-url=$org_label_schema_vcs_url \
      org.label-schema.vcs-ref=$org_label_schema_vcs_ref \
      org.label-schema.build-date=$org_label_schema_build_date \
      org.opencord.vcs-commit-date=$org_opencord_vcs_commit_date \
      org.opencord.vcs-dirty=$org_opencord_vcs_dirty \
      org.opencord.gocover-cobertura-version=$GOCOVER_COBERTURA_VERSION
