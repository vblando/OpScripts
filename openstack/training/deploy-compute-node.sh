#!/bin/bash
# Reference:    https://docs.openstack.org/install-guide/openstack-services.html
#
# vlad (about.me/vblando)

COMMON_PASSWORD = 'klnm12'
CONFIG_DIR = '/root/configdir'

# setup the hosts file
echo "172.20.30.80 controller" >> /etc/hosts
echo "172.20.30.90 network" >> /etc/hosts
echo "172.20.30.100 compute" >> /etc/hosts
echo "172.20.30.200 storage" >> /etc/hosts

# install lvm
apt -y install lvm2 thin-provisioning-tools

# create the lvm volume
free_device=$(losetup -f)
fallocate -l 5G /var/lib/cinder_data.img
losetup $free_device /var/lib/cinder_data.img
pvcreate $free_device
vgcreate cinder-volumes $free_device

/bin/cp -r $CONFIG_DIR/storage-lvm-conf /etc/lvm/lvm.conf

# install cinder-volume
apt -y install cinder-volume
/bin/cp -r $CONFIG_DIR/storage-cinder-conf /etc/cinder/cinder.conf

# restart the services
service tgt restart
service cinder-volume restart
