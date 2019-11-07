#!/bin/bash
#
# OpenStack Multiple Project/Tenant Creation Script
# Reference: https://github.com/OpenStackSanDiego/OpenStack-on-Packet-Host
#            
# vlad (about.me/vblando)

for i in a b c ;
do
        project=tenant_$i
        user=tenant_$i

        echo "Creating Project $project for User $user"
        openstack project create $project
        openstack user create --password "1q2w3e4r" $user
        openstack role create $user
        openstack role add --project $project --user $user $user

        echo "Setting the Project quota"
        project_id=`openstack project list |grep tenant_a | awk '{print $2}'`
        openstack quota set --instances 10 $project_id
        openstack quota set --floating-ips 10 $project_id
        openstack quota set --cores 20 $project_id
        openstack quota set --ram 20480 $project_id

done
