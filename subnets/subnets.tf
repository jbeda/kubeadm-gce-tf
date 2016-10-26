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

// This module does all of the subnet/CIDR math.  This is the only way I could
// figure in terraform to create "local" variables.

variable "cidr" {}
variable "num-nodes" {}

// This is the CIDR to be used by VMs themselves.
output "host_cidr" {
  value = "${cidrsubnet("${var.cidr}", 8, 0)}"
}

// This is the CIDR that Kubernetes will draw from for Service virtual IPs.
output "service_cidr" {
  value = "${cidrsubnet("${var.cidr}", 8, 1)}"
}

// This is the IP address that will host the DNS server.  This is a virtual IP
// drawn from the service_cidr range.
output "dns_service_ip" {
  value = "${cidrhost("${cidrsubnet("${var.cidr}", 8, 1)}", 10)}"
}

// This is the CIDR range for containers running on the master.
output "master_container_cidr" {
  value = "${cidrsubnet("${var.cidr}", 8, 2)}"
}

// This is the IP address of the master itself.  This is drawn from the
// host_cidr range.
output "master_ip" {
  value = "${cidrhost("${cidrsubnet("${var.cidr}", 8, 0)}", 2)}"
}

// This resource helps us to compute some stuff per node
resource "null_resource" "nodes" {
  count = "${var.num-nodes}"

  triggers {
    // This is the VM IP for each node
    host_ip        = "${cidrhost("${cidrsubnet("${var.cidr}", 8, 0)}", 3+count.index)}"

    // This is the CIDR range for containers running on this node.
    container_cidr = "${cidrsubnet("${var.cidr}", 8, 3+count.index)}"
  }
}

// This is an array of all of the host IPs for each node
output "node_ips" {
  value = ["${null_resource.nodes.*.triggers.host_ip}"]
}

// This is the CIDR ranges per node for containers running on those nodes.
output "node_container_cidrs" {
  value = ["${null_resource.nodes.*.triggers.container_cidr}"]
}
