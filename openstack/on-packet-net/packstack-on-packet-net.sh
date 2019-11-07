#!/bin/bash

# Reference:    https://www.rdoproject.org/install/packstack/
#		https://github.com/openstack/kolla-ansible/
#               https://github.com/OpenStackSanDiego/OpenStack-on-Packet-Host
#
# Vlad (about.me/vblando)

# OpenStack Release (queens|rock|stein)
RELEASE=queens

#Install the RDO Repository for Queens/Rocky/Stein
yum install -y centos-release-openstack-$RELEASE
yum-config-manager --enable openstack-$RELEASE

# Update the current packages
yum update -y

# Install Packstack installer
yum install -y openstack-packstack

# download the working packstack answerfile from
# https://raw.githubusercontent.com/vblando/scripts/master/packstack-answerfile-for-packetnet
# and edit it according to your requirement

# Before deploying make sure that the controller can SSH to the compute(s)
# Begin deploying OpenStack 
ANSWERFILE_PATH=/root
time packstack --answer-file $ANSWERFILE_PATH/packstack-answerfile-for-packetnet

# Source the RC file
. ~/keystonerc_admin

# Download a test Linux Image
ARCH=$(uname -m)
IMAGE_PATH=/root/
IMAGE_URL=http://download.cirros-cloud.net/0.4.0/
IMAGE=cirros-0.4.0-${ARCH}-disk.img
IMAGE_NAME=cirros
IMAGE_TYPE=linux

echo Checking for locally available cirros image.
# Let's first try to see if the image is available locally
# nodepool nodes caches them in $IMAGE_PATH
if ! [ -f "${IMAGE_PATH}/${IMAGE}" ]; then
    IMAGE_PATH='./'
    if ! [ -f "${IMAGE_PATH}/${IMAGE}" ]; then
        echo None found, downloading cirros image.
        curl -L -o ${IMAGE_PATH}/${IMAGE} ${IMAGE_URL}/${IMAGE}
    fi
else
    echo Using cached cirros image from the nodepool node.
fi

EXTRA_PROPERTIES=
if [ ${ARCH} == aarch64 ]; then
    EXTRA_PROPERTIES="--property hw_firmware_type=uefi"
fi

echo Creating glance image.
openstack image create \
		--disk-format qcow2 \
		--container-format bare \ 
		--public \
		--property os_type=${IMAGE_TYPE} ${EXTRA_PROPERTIES} \
		--file ${IMAGE_PATH}/${IMAGE} ${IMAGE_NAME} \


# Fix the networking

GATEWAY=`ip route list | egrep "^default" | cut -d' ' -f 3`
IP=`hostname -I | cut -d' ' -f 1`
SUBNET=`ip -4 -o addr show dev bond0 | grep $IP | cut -d ' ' -f 7`

ip route del default via $GATEWAY dev bond0
ip addr del $SUBNET dev bond0
ip addr add $SUBNET dev br-ex
ifconfig br-ex up
ovs-vsctl add-port br-ex bond0
ip route add default via $GATEWAY dev br-ex

# If everything works up to this point
# Modify and Run packet-openstack-networking.sh
# Download it here 
# https://raw.githubusercontent.com/vblando/scripts/master/packet-openstack-networking.sh

# END #
