#!/bin/bash

# Copyright 2016 Joe Beda
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

set -x
set -o errexit
set -o nounset
set -o pipefail

if [[ ! -f k8s-gcr-auth-ro.json ]]; then
  SA_EMAIL=$(gcloud iam service-accounts --format='value(email)' create k8s-gcr-auth-ro)
  gcloud iam service-accounts keys create k8s-gcr-auth-ro.json --iam-account=$SA_EMAIL
  PROJECT=$(gcloud config list core/project --format='value(core.project)')
  gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:$SA_EMAIL --role roles/storage.objectViewer
fi

# Create a secret to hold the SA auth info
kubectl create secret docker-registry gcr.io \
  --docker-username=_json_key \
  --docker-email=user@example.com \
  --docker-server="https://gcr.io" \
  --docker-password="$(cat k8s-gcr-auth-ro.json)"

# Make this secret be the default one to use for this namespace
kubectl patch serviceaccount default \
  -p '{"imagePullSecrets": [{"name": "gcr.io"}]}'
