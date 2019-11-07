#!/bin/bash

# Source the tenant RC file before running this script
#
# vlad (about.me/vblando)
#

tenant="student_a"

# Create Network
openstack network create $tenant-network

# Create Subnet
openstack subnet create \
        --subnet-range 172.20.30.0/24 \
        --network $tenant-network  \
        --gateway 172.20.30.1 \
        --dns-nameserver 8.8.8.8 \
        $tenant-subnet

# Create Router
openstack router create $tenant-router
openstack router add subnet $tenant-router $tenant-subnet
openstack router set --external-gateway external_network $tenant-router

# Import the keypairs
openstack keypair create --public-key /opt/vlad/vlad.pub vlad
openstack keypair create --public-key /opt/vlad/asami.pub asami

# Create Ports for fixed IP
openstack port create --network $tenant-network --fixed-ip ip-address=172.20.30.80 controller1
openstack port create --network $tenant-network --fixed-ip ip-address=172.20.30.81 controller2
openstack port create --network $tenant-network --fixed-ip ip-address=172.20.30.90 network
openstack port create --network $tenant-network --fixed-ip ip-address=172.20.30.100 compute1
openstack port create --network $tenant-network --fixed-ip ip-address=172.20.30.101 compute2
openstack port create --network $tenant-network --fixed-ip ip-address=172.20.30.200 storage1
openstack port create --network $tenant-network --fixed-ip ip-address=172.20.30.201 storage2

# launch the VMs
controller1_ip=`openstack port list |grep controller1| awk '{print $2}'`
controller2_ip=`openstack port list |grep controller2| awk '{print $2}'`
network_ip=`openstack port list |grep network | awk '{print $2}'`
compute1_ip=`openstack port list |grep compute1 | awk '{print $2}'`
compute2_ip=`openstack port list |grep compute2 | awk '{print $2}'`
storage1_ip=`openstack port list |grep storage1 | awk '{print $2}'`
storage2_ip=`openstack port list |grep storage2 | awk '{print $2}'`

openstack server create --flavor openstack-controller.flavor --image "Ubuntu 16.04 LTS" --key-name vlad --nic port-id=$controller1_ip controller | sleep 10
openstack server create --flavor openstack-network.flavor --image "Ubuntu 16.04 LTS" --key-name vlad --nic port-id=$network_ip network | sleep 10
openstack server create --flavor openstack-compute.flavor --image "Ubuntu 16.04 LTS" --key-name vlad --nic port-id=$compute1_ip compute | sleep 10
openstack server create --flavor openstack-storage.flavor --image "Ubuntu 16.04 LTS" --key-name vlad --nic port-id=$storage1_ip storage | sleep 10

# Additional VMs
#openstack server create --flavor openstack-controller.flavor --image "Ubuntu 16.04 LTS" --key-name vlad --nic port-id=$controller1_ip controller | sleep 10
#openstack server create --flavor openstack-compute.flavor --image "Ubuntu 16.04 LTS" --key-name vlad --nic port-id=$compute2_ip compute2 | sleep 10
#openstack server create --flavor openstack-storage.flavor --image "Ubuntu 16.04 LTS" --key-name vlad --nic port-id=$storage2_ip storage2
