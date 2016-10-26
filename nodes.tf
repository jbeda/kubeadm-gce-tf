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

////////////////////////////////////////////////////////////////////////////////
// Start up scripts

// This script will install docker, the kubelet and configure networking on the
// node.
data "template_file" "prereq-node" {
  count    = "${var.num-nodes}"
  template = "${file("scripts/prereq.sh")}"

  vars {
    bridge-cidr = "${element(module.subnets.node_container_cidrs, count.index)}"
    dns-ip      = "${module.subnets.dns_service_ip}"
  }
}

// This script will have the node join the master.  It verifies itself with the
// token.
data "template_file" "node" {
  template = "${file("scripts/node.sh")}"

  vars {
    token     = "${var.bootstrap_token}"
    master-ip = "${google_compute_instance.master.network_interface.0.address}"
  }
}

// Package all of this up in to one base64 encoded string so that cloud init in
// the VM can run these scripts once booted.
data "template_cloudinit_config" "node" {
  count         = "${var.num-nodes}"
  base64_encode = true
  gzip          = true

  part {
    filename     = "scripts/per-instance/10-prereq.sh"
    content_type = "text/x-shellscript"
    content      = "${element(data.template_file.prereq-node.*.rendered, count.index)}"
  }

  part {
    filename     = "scripts/per-instance/20-node.sh"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.node.rendered}"
  }

  // Note that this script is run per boot while the others are only run once
  // per instance.
  part {
    filename     = "scripts/per-boot/10-iptables.sh"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.iptables.rendered}"
  }
}

////////////////////////////////////////////////////////////////////////////////
// Networking

// Set up a route per node so that all traffic to the container subnet (per
// node) will be routed to that node.
resource "google_compute_route" "node" {
  count                  = "${var.num-nodes}"
  name                   = "${var.cluster-name-base}-node-${count.index}"
  dest_range             = "${element(module.subnets.node_container_cidrs, count.index)}"
  network                = "${google_compute_network.network.name}"
  next_hop_instance      = "${element(google_compute_instance.node.*.name, count.index)}"
  next_hop_instance_zone = "${var.zone}"
  priority               = 10
}

////////////////////////////////////////////////////////////////////////////////
// VMs

resource "google_compute_instance" "node" {
  count          = "${var.num-nodes}"
  name           = "${var.cluster-name-base}-node-${count.index}"
  machine_type   = "${var.node_machine_type}"
  zone           = "${var.zone}"

  // This allows this VM to send traffic from containers without NAT.  Without
  // this set GCE will verify that traffic from a VM only comes from an IP
  // assigned to that VM.
  can_ip_forward = true

  disk {
    image = "ubuntu-os-cloud/ubuntu-1604-lts"
    type  = "pd-ssd"
    size  = "200"
  }

  metadata {
    "user-data" = "${element(data.template_cloudinit_config.node.*.rendered, count.index)}"
    "user-data-encoding" = "base64"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet.name}"
    address    = "${element(module.subnets.node_ips, count.index)}"

    access_config {
      // Ephemeral IP
    }
  }
}
