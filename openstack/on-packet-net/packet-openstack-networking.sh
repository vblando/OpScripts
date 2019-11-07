#!/bin/bash
#
# Reference: https://github.com/openstack/kolla-ansible/
#
# When provisioning for your packet server, make sure that you use /28 so you can have IPs
# for your floating IP pool
# 
# This EXT_NET_CIDR is your public network,that you want to connect to the internet
# EXT_NET_CIDR    = is your /28 Public IP block
# EXT_NET_RANGE   = use an ip calculator to determine the start and end of the range
#                   usually start at the IP next to the IP of the server
# EXT_NET_GATEWAY = your server's gateway

EXT_NET_CIDR='packet_public_ip_cidr'
EXT_NET_RANGE='start=starting_ip_of_the_range,end=ending_ip_of_the_range'
EXT_NET_GATEWAY='your_packet_server_gateway_ip'

neutron net-create external_network \
                --provider:network_type flat \
                --provider:physical_network extnet  \
                --router:external
neutron subnet-create --name public_subnet \
                --enable_dhcp=False \
                --allocation-pool=${EXT_NET_RANGE} \
                --gateway=${EXT_NET_GATEWAY} external_network ${EXT_NET_CIDR}
