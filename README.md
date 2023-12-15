# Dockerized Tools for Voltha

This repo contains Dockerfiles used to generate versioned tool containers.

## Versioning

Final docker images are tagged with the image version from the VERSION file.  This allows projects to specify a single "voltha toolchain version" and get all relevant tool versions.

The VERSION file should be changed using these rules:

* Bump Patch version if:
  * Patch version of a tool has changed.
  * This repo's supporting files have changed (Makefile, readme, etc.)  This rule assumes that the containers generated are backwards-compatible; if they are not, bump the major version instead.
* Bump Minor version if:
  * Minor version of a tool has changed.
  * A new tool has been added.
* Bump Major version if:
  * Major version of a tool has changed.
* Bump patch/minor/major version according to semver rules if a Dockerfile is changed.
* Reset lesser versions if greater versions change.
* Do not use -dev versions.

## Tool Usage

Only use containers tagged with `<VERSION>-tool`.<br/>
Do NOT use containers tagged with `tool-<TOOL_VERSION>`.

Some examples of how to use these containers:

* golang -
  `docker run --rm --user $(id -u):$(id -g) -v $PWD:/app -v gocache:/.cache -v gocache-${VOLTHA_TOOLS_VERSION}:/go/pkg voltha/voltha-ci-tools:${VOLTHA_TOOLS_VERSION}-golang go <args>`
* golangci-lint -
  `docker run --rm --user $(id -u):$(id -g) -v $PWD:/app -v gocache:/.cache -v gocache-${VOLTHA_TOOLS_VERSION}:/go/pkg voltha/voltha-ci-tools:${VOLTHA_TOOLS_VERSION}-golangci-lint golangci-lint <args>`
* protoc -
  `docker run --rm --user $(id -u):$(id -g) -v $PWD:/app voltha/voltha-ci-tools:${VOLTHA_TOOLS_VERSION}-protoc protoc <args>`
* hadolint -
  `docker run --rm --user $(id -u):$(id -g) -v $PWD:/app voltha/voltha-ci-tools:${VOLTHA_TOOLS_VERSION}-hadolint hadolint <args>`

Details:

* `--user` is specified so that generated files have sane ownership and permissions.
* `-v` bind-mounts the local folder into the container.
* `-v` is also used by golang containers to bind-mount volumes for caches.

## Key Commands

* `make build` to build containers
* `make lint` to lint the Dockerfiles
* `make docker-push` to push built containers to a registry

## Docker Image Upgrades

- [v2.6.0](docs/upgrade.md)
