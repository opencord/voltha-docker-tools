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
VERSION               ?= $(shell cat ./VERSION)
PROTOC_VERSION        ?= "3.7.0"
PROTOC_SHA256SUM      ?= "a1b8ed22d6dc53c5b8680a6f1760a305b33ef471bece482e92728f00ba2a2969"
PROTOC_GEN_GO_VERSION ?= "1.3.1"
GOLANG_VERSION        ?= "1.12.15"
GOLANGCI_LINT_VERSION ?= "1.17.0"
HADOLINT_VERSION      ?= "1.17.4"

# Docker related
DOCKER_LABEL_VCS_DIRTY     = false
ifneq ($(shell git status --porcelain | wc -l | sed -e 's/ //g'),0)
    DOCKER_LABEL_VCS_DIRTY = true
    VERSION                = latest
endif

DOCKER_EXTRA_ARGS          ?=
DOCKER_REGISTRY            ?= voltha
DOCKER_REPOSITORY          ?= voltha-ci-tools
IMAGENAME                  = ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}

## Docker labels. Only set ref and commit date if committed
DOCKER_LABEL_VCS_URL       ?= $(shell git remote get-url "$(shell git remote)" 2>/dev/null)
DOCKER_LABEL_VCS_REF       = $(shell git rev-parse HEAD)
DOCKER_LABEL_BUILD_DATE    ?= $(shell date -u "+%Y-%m-%dT%H:%M:%SZ")
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
HADOLINT = docker run --rm --user $$(id -u):$$(id -g) -v $$PWD:/app ${IMAGENAME}:${VERSION}-hadolint hadolint

lint: docker-lint

docker-lint: hadolint
	@echo "Linting Dockerfiles..."
	@${HADOLINT} $(shell ls docker/*.Dockerfile)


build: golang protoc golangci-lint hadolint

golang:
	docker build ${DOCKER_BUILD_ARGS} \
	--build-arg GOLANG_VERSION=${GOLANG_VERSION} \
	-t ${IMAGENAME}:${VERSION}-golang \
	-f docker/golang.Dockerfile .

golangci-lint:
	docker build ${DOCKER_BUILD_ARGS} \
	--build-arg GOLANGCI_LINT_VERSION=${GOLANGCI_LINT_VERSION} \
	-t ${IMAGENAME}:${VERSION}-golangci-lint \
	-f docker/golangci-lint.Dockerfile .

hadolint:
	docker build ${DOCKER_BUILD_ARGS} \
    --build-arg HADOLINT_VERSION=${HADOLINT_VERSION} \
    -t ${IMAGENAME}:${VERSION}-hadolint \
    -f docker/hadolint.Dockerfile .

protoc:
	docker build ${DOCKER_BUILD_ARGS} \
	--build-arg PROTOC_VERSION=${PROTOC_VERSION} \
	--build-arg PROTOC_SHA256SUM=${PROTOC_SHA256SUM} \
	--build-arg PROTOC_GEN_GO_VERSION=${PROTOC_GEN_GO_VERSION} \
	-t ${IMAGENAME}:${VERSION}-protoc \
	-f docker/protoc.Dockerfile .

docker-push:
ifneq (false,$(DOCKER_LABEL_VCS_DIRTY))
	@echo "Local repo is dirty.  Refusing to push."
	@exit 1
endif
	docker push ${IMAGENAME}:${VERSION}-golang
	docker push ${IMAGENAME}:${VERSION}-hadolint
	docker push ${IMAGENAME}:${VERSION}-protoc

