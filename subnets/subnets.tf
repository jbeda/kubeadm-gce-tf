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

variable "cidr" {
  default = "10.20.0.0/16"
}

variable "num-nodes" {}

output "host_cidr" {
  value = "${cidrsubnet("${var.cidr}", 8, 0)}"
}

output "service_cidr" {
  value = "${cidrsubnet("${var.cidr}", 8, 1)}"
}

output "dns_service_ip" {
  value = "${cidrhost("${cidrsubnet("${var.cidr}", 8, 1)}", 10)}"
}

output "master_container_cidr" {
  value = "${cidrsubnet("${var.cidr}", 8, 2)}"
}

output "master_ip" {
  value = "${cidrhost("${cidrsubnet("${var.cidr}", 8, 0)}", 2)}"
}

resource "null_resource" "nodes" {
  count = "${var.num-nodes}"

  triggers {
    host_ip        = "${cidrhost("${cidrsubnet("${var.cidr}", 8, 0)}", 3+count.index)}"
    container_cidr = "${cidrsubnet("${var.cidr}", 8, 3+count.index)}"
  }
}

output "node_ips" {
  value = ["${null_resource.nodes.*.triggers.host_ip}"]
}

output "node_container_cidrs" {
  value = ["${null_resource.nodes.*.triggers.container_cidr}"]
}
