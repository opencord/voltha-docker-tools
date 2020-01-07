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

* golang - `docker run --rm --user $(id -u):$(id -g) -v $PWD:/workdir -e GO111MODULE=on voltha/voltha-tools:${VOLTHA_TOOLS_VERSION}-golang go <args>`
* protoc - `docker run --rm --user $(id -u):$(id -g) -v $PWD:/workdir voltha/voltha-tools:${VOLTHA_TOOLS_VERSION}-protoc protoc <args>`
* golangci-lint - `docker run --rm -v $(pwd):/app -w /app voltha/voltha-tools:${VOLTHA_TOOLS_VERSION}-golangci-lint golangci-lint <args>`

Details:

* `--user` is specified so that generated files have sane ownership and permissions.
* `-v` bind-mounts the local folder into the container.

## Key Commands

* `make build` to build containers
* `make docker-push` to push built containers to a registry
