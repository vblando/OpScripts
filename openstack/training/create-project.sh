#!/bin/bash
#
# OpenStack Multiple Project/Tenant Creation Script
#
# - vlad (about.me/vblando)
#

for i in a b c d ;
do
        project=Student_$i
        user=student_$i

        echo "Creating Project $project for User $user"
        openstack project create $project
        openstack user create --password "1q2w3e4r" $user
        openstack role create $user
        openstack role add --project $project --user $user $user

        echo "Setting the Project quota"
        project_id=`openstack project list |grep $project | awk '{print $2}'`
        openstack quota set --instances 7 $project_id
        openstack quota set --floating-ips 1 $project_id
        openstack quota set --cores 20 $project_id
        openstack quota set --ram 50000 $project_id

done
