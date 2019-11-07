#!/bin/bash
#
# Reference: 
# https://docs.openstack.org/kolla-ansible/rocky/
#
# vlad (about.me/vblando)

echo "Install EPEL Repo"
yum -y install epel-release

echo "Update the system"
yum -y update

echo "Install PIP"
yum -y install python-pip

echo "Upgrade PIP to latest"
pip install -U pip

echo "Install dependencies"
yum -y install python-devel libffi-devel gcc openssl-devel libselinux-python

echo "Install Ansible"
pip install ansible

echo "Removing old python packages"
# these 2 packages causes kolla-ansible installation to fail
file1=`rpm -qa |grep PyYAML`
file2=`rpm -qa |grep python-requests`
rpm -e --nodeps $file1
rpm -e --nodeps $file2

echo "Install kolla-ansible"
pip install kolla-ansible

echo "Prepare kolla directory"
mkdir -p /etc/kolla/config

echo "Copy the templates and inventory files"
cd /etc/kolla
cp /usr/share/kolla-ansible/ansible/inventory/* .
cp /usr/share/kolla-ansible/etc_examples/kolla/* .
cp /usr/share/kolla-ansible/init-runonce .

echo "Generate password file"
cd /etc/kolla
kolla-genpwd

## Proceed to the documentation ##
