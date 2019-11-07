#!/bin/bash
# Reference:    https://docs.openstack.org/install-guide/openstack-services.html
#
# vlad (about.me/vblando)

COMMON_PASSWORD = '123qwe'
CONFIG_DIR = '/root/openstack-configs'

# setup the hosts file
echo "172.20.30.80 controoller" >> /etc/hosts
echo "172.20.30.90 network" >> /etc/hosts
echo "172.20.30.100 compute" >> /etc/hosts
echo "172.20.30.200 storage" >> /etc/hosts

# setup ntp
apt -y install chrony
/bin/cp -r $CONFIG_DIR/controller-chrony-conf /etc/chrony/chrony.conf
service chrony restart

# enable queens repository
apt -y install software-properties-common
add-apt-repository -y cloud-archive:queens
apt -y update

# install openStack client
apt -y install python-openstackclient

# install mariadb
apt -y install mariadb-server python-pymysql
/bin/cp -r $CONFIG_DIR/controller-99-openstack.cnf /etc/mysql/mariadb.conf.d/99-openstack.cnf
service mysql restart

# secure mariadb
mysql -e "UPDATE mysql.user SET Password = PASSWORD('$COMMON_PASSWORD') WHERE User = 'root'"
mysql -e "DROP USER ''@'localhost'"
mysql -e "DROP USER ''@'$(hostname)'"
mysql -e "DROP DATABASE test"
mysql -e "FLUSH PRIVILEGES"

# install rabbitmq
apt -y install rabbitmq-server
rabbitmqctl add_user openstack $COMMON_PASSWORD
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

# install memcached
apt -y install memcached python-memcache
/bin/cp -r $CONFIG_DIR/controller-memcachec-conf /etc/memcached.conf
service memcached restart

# install etcd
apt -y install etcd
/bin/cp -r $CONFIG_DIR/controller-etcd /etc/default/etcd
systemctl enable etcd
systemctl start etcd

# install keystone
mysql -e "CREATE DATABASE keystone"
mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$COMMON_PASSWORD'"
mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$COMMON_PASSWORD'"

apt -y install keystone apache2 libapache2-mod-wsgi
/bin/cp -r $CONFIG_DIR/controller-keystone-conf /etc/keystone/keystone.conf
su -s /bin/sh -c "keystone-manage db_sync" keystone

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

keystone-manage bootstrap --bootstrap-password $COMMON_PASSWORD \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne

/bin/cp -r $CONFIG_DIR/controller-apache2-conf /etc/apache2/apache2.conf
service apache2 restart

export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3

# create a domain, projects, users, and roles
openstack domain create --description "An Example Domain" example
openstack project create --domain default --description "Service Project" service
openstack project create --domain default --description "Demo Project" demo
openstack user create --domain default --password-prompt demo
openstack role create user
openstack role add --project demo --user demo user

# create the environment script
/bin/cp -r $CONFIG_DIR/controller-admin-openrc /root/admin-openrc

# install glance
mysql -e "CREATE DATABASE glance"
mysql -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$COMMON_PASSWORD'"
mysql -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$COMMON_PASSWORD'"

. /root/admin-openrc
openstack user create --domain default --password-prompt glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image
openstack endpoint create --region RegionOne image public http://controller:9292
openstack endpoint create --region RegionOne image internal http://controller:9292
openstack endpoint create --region RegionOne image admin http://controller:9292

apt -y install glance
/bin/cp -r $CONFIG_DIR/controller-glance-api-conf /etc/glance/glance-api.conf
/bin/cp -r $CONFIG_DIR/controller-glance-registry-conf /etc/glance/glance-registry.conf
u -s /bin/sh -c "glance-manage db_sync" glance

service glance-registry restart
service glance-api restart

cd /root && wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

openstack image create "cirros" \
  --file /root/cirros-0.4.0-x86_64-disk.img \
  --disk-format qcow2 --container-format bare \
  --public

# install nova
mysql -e "CREATE DATABASE nova_api"
mysql -e "CREATE DATABASE nova"
mysql -e "CREATE DATABASE nova_cell0"

mysql -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '$COMMON_PASSWORD'"
mysql -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '$COMMON_PASSWORD'"
mysql -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$COMMON_PASSWORD'"
mysql -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$COMMON_PASSWORD'"
mysql -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY '$COMMON_PASSWORD'"
mysql -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY '$COMMON_PASSWORD'"

. /root/admin-openrc
openstack user create --domain default --password $COMMON_PASSWORD nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1

openstack user create --domain default --password $COMMON_PASSWORD placement
openstack role add --project service --user placement admin
openstack service create --name placement --description "Placement API" placement
openstack endpoint create --region RegionOne placement public http://controller:8778
openstack endpoint create --region RegionOne placement interal http://controller:8778
openstack endpoint create --region RegionOne placement admin http://controller:8778

apt -y install nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler nova-placement-api
/bin/cp -r $CONFIG_DIR/controller-nova-conf /etc/nova/nova.conf
su -s /bin/sh -c "nova-manage api_db sync" nova

su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
su -s /bin/sh -c "nova-manage db sync" nova

service nova-api restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

# install cinder
mysql -e "CREATE DATABASE cinder"
mysql -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '$COMMON_PASSWORD'"
mysql -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '$COMMON_PASSWORD'"

. /root/admin-openrc
openstack user create --domain default --password $COMMON_PASSWORD cinder
openstack role add --project service --user cinder admin
openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3

openstack endpoint create --region RegionOne volumev2 public http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev2 internal http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev2 admin http://controller:8776/v2/%\(project_id\)s

openstack endpoint create --region RegionOne volumev3 public http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 internal http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 admin http://controller:8776/v3/%\(project_id\)s

apt -y install cinder-api cinder-scheduler
/bin/cp -r $CONFIG_DIR/controller-cinder-conf /etc/cinder/cinder.conf
su -s /bin/sh -c "cinder-manage db sync" cinder

service nova-api restart
service cinder-scheduler restart
service apache2 restart

# install dashboard
apt -y install openstack-dashboard
/bin/cp -r $CONFIG_DIR/controller-local-settings-py /etc/openstack-dashboard/local_settings.py
/bin/cp -r $CONFIG_DIR/controller-openstack-dashboard-conf /etc/apache2/conf-available/openstack-dashboard.conf
service apache2 reload

# install neutron
mysql -e "CREATE DATABASE neutron"
mysql -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$COMMON_PASSWORD'"
mysql -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$COMMON_PASSWORD'"

. /root/admin-openrc
openstack user create --domain default --password $COMMON_PASSWORD neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network

openstack endpoint create --region RegionOne network public http://controller:9696
openstack endpoint create --region RegionOne network internal http://controller:9696
openstack endpoint create --region RegionOne network admin http://controller:9696

apt -y install neutron-server neutron-plugin-ml2 \
  neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent \
  neutron-metadata-agent

/bin/cp -r $CONFIG_DIR/controller-neutron-conf /etc/neutron/neutron.conf
/bin/cp -r $CONFIG_DIR/controller-ml2-conf-ini /etc/neutron/plugins/ml2/ml2_conf.ini
/bin/cp -r $CONFIG_DIR/controller-linuxbridge-agent-ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini
/bin/cp -r $CONFIG_DIR/controller-sysctl-conf /etc/sysctl.conf
/bin/cp -r $CONFIG_DIR/controller-l3-agent-ini /etc/neutron/l3_agent.ini
/bin/cp -r $CONFIG_DIR/controller-dhcp-agent-ini /etc/neutron/dhcp_agent.ini

modprobe br_netfilter
echo "br_netfilter" > /etc/modules-load.d/br_netfilter.conf
sysctl -p /etc/sysctl.conf

/bin/cp -r $CONFIG_DIR/controller-metadata-agent-ini /etc/neutron/metadata_agent.ini
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

service nova-api restart
service neutron-server restart
service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart

# end
