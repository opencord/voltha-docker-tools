# -*- makefile -*-
# -----------------------------------------------------------------------
# Copyright 2020-2024 Open Networking Foundation (ONF) and the ONF Contributors
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

FROM python:3.8.5-alpine

RUN pip install -I tox==3.19.0 && pip install -I bandit==1.6.2

WORKDIR /app

# Label image
ARG org_label_schema_version=unknown
ARG org_label_schema_vcs_url=unknown
ARG org_label_schema_vcs_ref=unknown
ARG org_label_schema_build_date=unknown
ARG org_opencord_vcs_commit_date=unknown
ARG org_opencord_vcs_dirty=unknown

LABEL org.label-schema.schema-version=1.0 \
      org.label-schema.name=voltha-pythonci-lint \
      org.label-schema.version=$org_label_schema_version \
      org.label-schema.vcs-url=$org_label_schema_vcs_url \
      org.label-schema.vcs-ref=$org_label_schema_vcs_ref \
      org.label-schema.build-date=$org_label_schema_build_date \
      org.opencord.vcs-commit-date=$org_opencord_vcs_commit_date \
      org.opencord.vcs-dirty=$org_opencord_vcs_dirty \
      org.opencord.python-version=3.8.5

# [EOF]
