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

data "template_file" "prereq-master" {
  template = "${file("scripts/prereq.sh")}"

  vars {
    bridge-cidr = "${module.subnets.master_container_cidr}"
    dns-ip      = "${module.subnets.dns_service_ip}"
  }
}

data "template_file" "master" {
  template = "${file("scripts/master.sh")}"

  vars {
    token        = "${var.bootstrap_token}"
    service-cidr = "${module.subnets.service_cidr}"
  }
}

data "template_cloudinit_config" "master" {
  base64_encode = true
  gzip          = true

  part {
    filename     = "scripts/per-instance/10-prereq.sh"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.prereq-master.rendered}"
  }

  part {
    filename     = "scripts/per-instance/20-master.sh"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.master.rendered}"
  }

  part {
    filename     = "scripts/per-boot/10-iptables.sh"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.iptables.rendered}"
  }
}

resource "google_compute_route" "master" {
  name                   = "${var.cluster-name-base}-master"
  dest_range             = "${module.subnets.master_container_cidr}"
  network                = "${google_compute_network.network.name}"
  next_hop_instance      = "${google_compute_instance.master.name}"
  next_hop_instance_zone = "${var.zone}"
  priority               = 10
}

resource "google_compute_instance" "master" {
  name           = "${var.cluster-name-base}-master"
  machine_type   = "${var.master_machine_type}"
  zone           = "${var.zone}"
  can_ip_forward = true

  disk {
    image = "ubuntu-os-cloud/ubuntu-1604-lts"
    type  = "pd-ssd"
    size  = "200"
  }

  metadata {
    "user-data" = "${data.template_cloudinit_config.master.rendered}"
    "user-data-encoding" = "base64"
}

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet.name}"
    address    = "${module.subnets.master_ip}"

    access_config {
      // Ephemeral IP
    }
  }
}
