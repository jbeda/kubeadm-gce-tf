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

resource "google_compute_network" "network" {
  name                    = "${var.cluster-name-base}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster-name-base}-default-${var.region}"
  ip_cidr_range = "${module.subnets.host_cidr}"
  network       = "${google_compute_network.network.name}"
}

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

resource "google_compute_firewall" "firewall-ssh" {
  name    = "${var.cluster-name-base}-ssh"
  network = "${google_compute_network.network.name}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

data "template_file" "iptables" {
  template = "${file("scripts/set-iptables.sh")}"

  vars {
    cidr = "${var.cidr}"
  }
}
