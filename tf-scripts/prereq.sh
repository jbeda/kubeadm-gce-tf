#!/bin/bash -v

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

# Download and install the latest Docker
curl -sSL https://get.docker.com/ | sh
systemctl start docker

# This sets up the DNS endpoint in the container.  This has to be coordinated
# with the service IP range set on the master.
mkdir -p /etc/systemd/system/kubelet.service.d
cat >/etc/systemd/system/kubelet.service.d/20-gcenet.conf <<EOF
[Service]
Environment="KUBELET_DNS_ARGS=--cluster-dns=${dns-ip} --cluster-domain=cluster.local"
EOF

# Install kubernetes apt source and the packages we'll need
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl kubernetes-cni

# Configure CNI
# Hairpin mode is complicated.  See https://github.com/kubernetes/kubernetes/issues/20096.
# Also https://github.com/torvalds/linux/commit/751eb6b6042a596b0080967c1a529a9fe98dac1d.
# Should be fixed in kernel 4.8
mkdir -p /etc/cni/net.d

# This sets up a bridge for containers called `cni0`.  All traffic off the
# machine will be forwarded (but not NATd) through the main interface.  IP
# addresses on the bridge will be allocated out of the `bridge-cdr` range.
cat >/etc/cni/net.d/10-gcenet.conf <<EOF
{
    "cniVersion": "0.2.0",
    "name": "gcenet",
    "type": "bridge",
    "mtu": 1460,
    "bridge": "cni0",
    "isGateway": true,
    "isDefaultGateway": true,
    "ipMasq": false,
    "hairpinMode": false,
    "ipam": {
        "type": "host-local",
        "subnet": "${bridge-cidr}"
    }
}
EOF

# This simply sets up a loopback interface in each container
cat >/etc/cni/net.d/99-loopback.conf <<EOF
{
    "cniVersion": "0.2.0",
    "name": "cni-loopback",
    "type": "loopback"
}
EOF
