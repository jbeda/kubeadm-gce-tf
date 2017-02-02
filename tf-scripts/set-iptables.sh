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

# All traffic that isn't to the internal network should be SNAT'd so it can egress
iptables --append POSTROUTING --table nat -m addrtype ! --dst-type LOCAL ! -d ${cidr} -j MASQUERADE

# Docker 1.13+ will set the FORWARD chain to DROP by default.  Make sure we allow cni0 through.
iptables -A FORWARD -i cni0 -j ACCEPT
iptables -A FORWARD -o cni0 -j ACCEPT