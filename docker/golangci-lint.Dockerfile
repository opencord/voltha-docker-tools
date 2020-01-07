ARG GOLANGCI_LINT_VERSION
FROM golangci/golangci-lint:v$GOLANGCI_LINT_VERSION

# Label image
ARG org_label_schema_version=unknown
ARG org_label_schema_vcs_url=unknown
ARG org_label_schema_vcs_ref=unknown
ARG org_label_schema_build_date=unknown
ARG org_opencord_vcs_commit_date=unknown
ARG org_opencord_vcs_dirty=unknown
ARG GOLANGCI_LINT_VERSION=unknown

LABEL org.label-schema.schema-version=1.0 \
      org.label-schema.name=voltha-golangci-lint \
      org.label-schema.version=$org_label_schema_version \
      org.label-schema.vcs-url=$org_label_schema_vcs_url \
      org.label-schema.vcs-ref=$org_label_schema_vcs_ref \
      org.label-schema.build-date=$org_label_schema_build_date \
      org.opencord.vcs-commit-date=$org_opencord_vcs_commit_date \
      org.opencord.vcs-dirty=$org_opencord_vcs_dirty \
      org.opencord.golangci-lint-version=$GOLANGCI_LINT_VERSION

