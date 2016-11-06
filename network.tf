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

// Create a whole new network for the Kubernetes cluster.  Make the subnets be
// manually managed.
resource "google_compute_network" "network" {
  name                    = "${var.cluster-name-base}"
  auto_create_subnetworks = false
}

// Create a subnet for the cluster in the region that we are running in.  Have
// it be just for the IPs that we'll assign to hosts.
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster-name-base}-default-${var.region}"
  ip_cidr_range = "${module.subnets.host_cidr}"
  network       = "${google_compute_network.network.name}"
}

// Allow all traffic between IPs on this network.
resource "google_compute_firewall" "firewall-internal" {
  name    = "${var.cluster-name-base}-internal"
  network = "${google_compute_network.network.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["1-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["1-65535"]
  }

  source_ranges = ["${var.cidr}"]
}

// Allow SSH (TCP port 22) traffic to reach our VMs on this network.
resource "google_compute_firewall" "firewall-ssh" {
  name    = "${var.cluster-name-base}-ssh"
  network = "${google_compute_network.network.name}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

// Set up a script that will run per-boot on the VM to set up IP tables.  This
// needs to know the overall CIDR so it can make sure that traffic not on that
// network gets NATd as it exits GCE.
data "template_file" "iptables" {
  template = "${file("tf-scripts/set-iptables.sh")}"

  vars {
    cidr = "${var.cidr}"
  }
}
