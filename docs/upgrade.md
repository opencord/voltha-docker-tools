Docker Image Upgrade: v2.6.0
============================

- Upgrade golang from v1.6.3 to v1.17.10
- Replace 'go get' with 'go install pkg@version'
- Deprecate GO111MODULES=on
- Split protobuf and grpc module installation into two commands,
  install by version requires packages to all be same namespace and version.
    
### Layer: golang

| Package | From      | To        | Notes                          |
| ------- | --------- | --------  | ------------------------------ |
| golang  | v1.16.3   | v1.17.10  | Upgrade inspired by VOLTHA VGC |
| git     | 2.30.2-r0 | 2.36.6-r0 | Update command line tool       |
| 

### Layer: gocover-cobertura

| Package    | From    | To       | Notes                          |
| ---------- | ------- | -------- | ------------------------------ |
| build-base | 0.5-r2  | 0.5-r3   |                                |

### Layer: go-junit-report

| Package    | From    | To       | Notes                          |
| ---------- | ------- | -------- | ------------------------------ |
| build-base | 0.5-r2  | 0.5-r3   |                                |

### Layer: protoc

| Package       | From      | To        | Notes                          |
| ------------- | -------   | --------- | ------------------------------ |
| alpine OS     | 3.13      | 3.16      | docker layer: cpp-build        |
| build-base    | 0.5-r2    | 0.5-r3    |                                |
| cmake         | 3.18.4-r1 | 3.23.5-r0 | Command line build tool        |
| git           | 2.30.2-r0 | 2.36.6-r0 | Command line interpreter       |
| libatomic     | 10.2.1_pre1-r3 | 11.2.1_git20220219-r2 |               |
| linux-headers | 5.7.8-r0  | 5.16.7-r1 | system header files            |
| musl          | 1.2.2-r0  | 1.2.3-r0  | C std lib built atop linux system call api |
| perl          | 5.32.0-r0 | 5.34.2-r0 | perl interpreter               |


v2.6.0: Lingering Problems
--------------------------    

Interactive fails, trying jenkins.

> RUN git clone --recurse-submodules -b v1.31.1         --depth=1 --shallow-submodules https://github.com/grpc/grpc
> #16 19.82 Cloning into '/src/grpc/third_party/re2'...
> #16 184.4 fatal: unable to connect to github.com:
> #16 184.4 github.com[0: 140.82.112.4]: errno=Connection refused
> #16 184.4 github.com[1: ::ffff:140.82.112.4]: errno=Connection refused
> #16 184.4 
> #16 184.4 fatal: clone of 'git://github.com/google/re2.git' into submodule path '/src/grpc/third_party/re2' failed
> #16 184.4 Failed to clone 'third_party/re2'. Retry scheduled
> #16 184.4 Cloning into '/src/grpc/third_party/udpa'...

protoc.Dockerfile:73
--------------------
  72 |     # Clone grpc and submodules
  73 | >>> RUN git clone --recurse-submodules -b v${PROTOC_GEN_CPP_VERSION} \
  74 | >>>         --depth=1 --shallow-submodules https://github.com/grpc/grpc


## TODO

- Replace github/protobuf with google/protobuf

    - #9 7.961 go: module github.com/golang/protobuf is deprecated: Use the "google.golang.org/protobuf" module instead.

- Replace alpine:3.8 with 3.16+ in onos-config-loader.Dockerfile

## See Also

- [pkgs.alpinelinux.org](https://pkgs.alpinelinux.org/packages)
- [v3.16 x86_64](https://dl-cdn.alpinelinux.org/alpine/v3.16/main/x86_64)

#### re2
- https://chromium.googlesource.com/external/github.com/grpc/grpc/+/HEAD/third_party/re2
- https://github.com/google/re2
- https://github.com/google/re2/releases/tag/2023-11-01

    