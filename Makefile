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

# set default shell options
SHELL = bash -e -o pipefail

## Variables
VERSION                         ?= $(shell cat ./VERSION)
GO_JUNIT_REPORT_VERSION         ?= "1.0.0"
GOCOVER_COBERTURA_VERSION       ?= "v0.0.0-20180217150009-aaee18c8195c"
GOLANG_VERSION                  ?= "1.25.3"
GOLANG_VERSION_FOR_PROTOC       ?= "1.16.3"
GOLANGCI_LINT_VERSION           ?= "2.5.0"
HADOLINT_VERSION                ?= "2.12.0"
PROTOC_VERSION                  ?= "3.7.0"
PROTOC_SHA256SUM                ?= "a1b8ed22d6dc53c5b8680a6f1760a305b33ef471bece482e92728f00ba2a2969"
PROTOC_GEN_GO_VERSION           ?= "1.3.2"
PROTOC_GEN_GRPC_GATEWAY_VERSION ?= "1.14.3"
PROTOC_GEN_CPP_VERSION          ?= "1.31.1"

# Docker related
DOCKER_LABEL_VCS_DIRTY     = false
ifneq ($(shell git status --porcelain | wc -l | sed -e 's/ //g'),0)
    DOCKER_LABEL_VCS_DIRTY = true
endif

DOCKER                     ?= docker
DOCKER_EXTRA_ARGS          ?=
DOCKER_REGISTRY            ?=
DOCKER_REPOSITORY          ?= voltha/
DOCKER_TAG                 ?= ${VERSION}$(shell [[ ${DOCKER_LABEL_VCS_DIRTY} == "true" ]] && echo "-dirty" || true)
IMAGENAME                  := ${DOCKER_REGISTRY}${DOCKER_REPOSITORY}voltha-ci-tools

## Docker labels. Only set ref and commit date if committed
DOCKER_LABEL_VCS_URL       = $(shell git remote get-url "$(shell git remote)" 2>/dev/null)
DOCKER_LABEL_VCS_REF       = $(shell git rev-parse HEAD)
DOCKER_LABEL_BUILD_DATE    = $(shell date -u "+%Y-%m-%dT%H:%M:%SZ")
DOCKER_LABEL_COMMIT_DATE   = $(shell git show -s --format=%cd --date=iso-strict HEAD)

DOCKER_BUILD_ARGS ?= \
	${DOCKER_EXTRA_ARGS} \
	--build-arg org_label_schema_version="${VERSION}" \
	--build-arg org_label_schema_vcs_url="${DOCKER_LABEL_VCS_URL}" \
	--build-arg org_label_schema_vcs_ref="${DOCKER_LABEL_VCS_REF}" \
	--build-arg org_label_schema_build_date="${DOCKER_LABEL_BUILD_DATE}" \
	--build-arg org_opencord_vcs_commit_date="${DOCKER_LABEL_COMMIT_DATE}" \
	--build-arg org_opencord_vcs_dirty="${DOCKER_LABEL_VCS_DIRTY}"

## runnable tool containers
HADOLINT = ${DOCKER} run --rm --user $$(id -u):$$(id -g) -v $$PWD:/app ${IMAGENAME}:${DOCKER_TAG}-hadolint hadolint

lint: docker-lint

docker-lint: hadolint
	@echo "Linting Dockerfiles..."
	@${HADOLINT} $(shell ls docker/*.Dockerfile)
	@echo "Dockerfiles linted OK"


build: docker-build

docker-build: go-junit-report gocover-cobertura golang golangci-lint hadolint protoc python onos-config-loader

go-junit-report:
	${DOCKER} build ${DOCKER_BUILD_ARGS} \
	--build-arg GOLANG_VERSION=${GOLANG_VERSION} \
	--build-arg GO_JUNIT_REPORT_VERSION=${GO_JUNIT_REPORT_VERSION} \
	-t ${IMAGENAME}:${DOCKER_TAG}-go-junit-report \
	-t ${IMAGENAME}:latest-go-junit-report \
	-f docker/go-junit-report.Dockerfile .

gocover-cobertura:
	${DOCKER} build ${DOCKER_BUILD_ARGS} \
	--build-arg GOLANG_VERSION=${GOLANG_VERSION} \
	--build-arg GOCOVER_COBERTURA_VERSION=${GOCOVER_COBERTURA_VERSION} \
	-t ${IMAGENAME}:${DOCKER_TAG}-gocover-cobertura \
	-t ${IMAGENAME}:latest-gocover-cobertura \
	-f docker/gocover-cobertura.Dockerfile .

golang:
	${DOCKER} build ${DOCKER_BUILD_ARGS} \
	--build-arg GOLANG_VERSION=${GOLANG_VERSION} \
	-t ${IMAGENAME}:${DOCKER_TAG}-golang \
	-t ${IMAGENAME}:latest-golang \
	-f docker/golang.Dockerfile .

python:
	${DOCKER} build ${DOCKER_BUILD_ARGS} \
	-t ${IMAGENAME}:${DOCKER_TAG}-python \
	-t ${IMAGENAME}:latest-python \
	-f docker/python.Dockerfile .

golangci-lint:
	${DOCKER} build ${DOCKER_BUILD_ARGS} \
	--build-arg GOLANGCI_LINT_VERSION=${GOLANGCI_LINT_VERSION} \
	-t ${IMAGENAME}:${DOCKER_TAG}-golangci-lint \
	-t ${IMAGENAME}:latest-golangci-lint \
	-f docker/golangci-lint.Dockerfile .

hadolint:
	${DOCKER} build ${DOCKER_BUILD_ARGS} \
    --build-arg HADOLINT_VERSION=${HADOLINT_VERSION} \
    -t ${IMAGENAME}:${DOCKER_TAG}-hadolint \
    -t ${IMAGENAME}:latest-hadolint \
    -f docker/hadolint.Dockerfile .

protoc:
	${DOCKER} build ${DOCKER_BUILD_ARGS} \
	--build-arg GOLANG_VERSION=${GOLANG_VERSION_FOR_PROTOC} \
	--build-arg PROTOC_VERSION=${PROTOC_VERSION} \
	--build-arg PROTOC_SHA256SUM=${PROTOC_SHA256SUM} \
	--build-arg PROTOC_GEN_GO_VERSION=${PROTOC_GEN_GO_VERSION} \
	--build-arg PROTOC_GEN_GRPC_GATEWAY_VERSION=${PROTOC_GEN_GRPC_GATEWAY_VERSION} \
	--build-arg PROTOC_GEN_CPP_VERSION=${PROTOC_GEN_CPP_VERSION} \
	-t ${IMAGENAME}:${DOCKER_TAG}-protoc \
	-t ${IMAGENAME}:latest-protoc \
	-f docker/protoc.Dockerfile .

onos-config-loader:
	${DOCKER} build ${DOCKER_BUILD_ARGS} \
	-t ${IMAGENAME}:${DOCKER_TAG}-onos-config-loader \
	-t ${IMAGENAME}:latest-onos-config-loader \
	-f docker/onos-config-loader.Dockerfile .

docker-push:
ifneq (false,$(DOCKER_LABEL_VCS_DIRTY))
	@echo "Local repo is dirty.  Refusing to push."
	@exit 1
endif
	${DOCKER} push ${IMAGENAME}:${DOCKER_TAG}-go-junit-report
	${DOCKER} push ${IMAGENAME}:${DOCKER_TAG}-gocover-cobertura
	${DOCKER} push ${IMAGENAME}:${DOCKER_TAG}-golang
	${DOCKER} push ${IMAGENAME}:${DOCKER_TAG}-golangci-lint
	${DOCKER} push ${IMAGENAME}:${DOCKER_TAG}-hadolint
	${DOCKER} push ${IMAGENAME}:${DOCKER_TAG}-protoc
	${DOCKER} push ${IMAGENAME}:${DOCKER_TAG}-python
	${DOCKER} push ${IMAGENAME}:${DOCKER_TAG}-onos-config-loader
