// Copyright 2016 Joe Beda
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

variable "cluster-name-base" {
  default = "kube"
}

variable "region" {
  default = "us-west1"
}

variable "zone" {
  default = "us-west1-a"
}

variable "project" {}

variable "master_machine_type" {
  default = "n1-standard-1"
}

variable "node_machine_type" {
  default = "n1-standard-1"
}

// This token is used to establish trust between nodes in the cluster.  You can
// generate it with the following snippet:
//
//   python -c 'import random; print "%0x.%0x" % (random.SystemRandom().getrandbits(3*8), random.SystemRandom().getrandbits(8*8))'
//
// The token has to be in the form of '<6 chars>.<16 chars>'
variable "bootstrap_token" {
  default = ""
}

variable "cidr" {
  default = "10.20.0.0/16"
}

variable "num-nodes" {
  default = 3
}
