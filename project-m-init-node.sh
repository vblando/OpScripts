#!/bin/bash
#
# vlad (about.me/vblando)

# Create bond1
cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-bond1
DEVICE=bond1
TYPE=Bond
NAME=bond1
BONDING_MASTER=yes
BOOTPROTO=none
ONBOOT=yes
BONDING_OPTS="mode=5 miimon=100"
MTU=9000
EOF

# configure bond1 members
# interface enp130s0f0
sed -i '/IPV/d' /etc/sysconfig/network-scripts/ifcfg-enp130s0f0
sed -i '/PROXY_METHOD/d' /etc/sysconfig/network-scripts/ifcfg-enp130s0f0
sed -i '/BROWSER_ONLY/d' /etc/sysconfig/network-scripts/ifcfg-enp130s0f0
sed -i '/BOOTPROTO/d' /etc/sysconfig/network-scripts/ifcfg-enp130s0f0
sed -i '/DEFROUTE/d' /etc/sysconfig/network-scripts/ifcfg-enp130s0f0
sed -i '/NAME/d' /etc/sysconfig/network-scripts/ifcfg-enp130s0f0
sed -i '/ONBOOT/d' /etc/sysconfig/network-scripts/ifcfg-enp130s0f0
echo "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-enp130s0f0
echo "BOOTPROTO=none" >> /etc/sysconfig/network-scripts/ifcfg-enp130s0f0
echo "MASTER=bond1" >> /etc/sysconfig/network-scripts/ifcfg-enp130s0f0
echo "SLAVE=yes" >> /etc/sysconfig/network-scripts/ifcfg-enp130s0f0
echo "USERCTL=no" >> /etc/sysconfig/network-scripts/ifcfg-enp130s0f0
echo "MTU=9000" >> /etc/sysconfig/network-scripts/ifcfg-enp130s0f0

# interface ens1f0
sed -i '/IPV/d' /etc/sysconfig/network-scripts/ifcfg-ens1f0
sed -i '/PROXY_METHOD/d' /etc/sysconfig/network-scripts/ifcfg-ens1f0
sed -i '/BROWSER_ONLY/d' /etc/sysconfig/network-scripts/ifcfg-ens1f0
sed -i '/BOOTPROTO/d' /etc/sysconfig/network-scripts/ifcfg-ens1f0
sed -i '/DEFROUTE/d' /etc/sysconfig/network-scripts/ifcfg-ens1f0
sed -i '/NAME/d' /etc/sysconfig/network-scripts/ifcfg-ens1f0
sed -i '/ONBOOT/d' /etc/sysconfig/network-scripts/ifcfg-ens1f0
echo "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-ens1f0
echo "BOOTPROTO=none" >> /etc/sysconfig/network-scripts/ifcfg-ens1f0
echo "MASTER=bond1" >> /etc/sysconfig/network-scripts/ifcfg-ens1f0
echo "SLAVE=yes" >> /etc/sysconfig/network-scripts/ifcfg-ens1f0
echo "USERCTL=no" >> /etc/sysconfig/network-scripts/ifcfg-ens1f0
echo "MTU=9000" >> /etc/sysconfig/network-scripts/ifcfg-ens1f0

# start the interfaces
ifup bond1 && ifup enp130s0f0 && ifup ens1f0

# stop and disable services
systemctl stop firewalld && systemctl disable firewalld
systemctl stop NetworkManager && systemctl disable NetworkManager
sleep 5
# reboot
