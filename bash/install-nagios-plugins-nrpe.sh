#!/bin/bash
#
# by vlad

# add the user and groups
useradd nagios && groupadd nagcmd && usermod -aG nagcmd nagios

# install the prerequisites
apt-get install build-essential libgd2-xpm-dev openssl libssl-dev unzip -y

# extract the plugins
tar xzvf nagios-nrpe-plugins.tgz

# compile the plugins
cd /root/nagios-plugins-*
./configure --with-nagios-user=nagios --with-nagios-group=nagios --with-openssl
make
make install

# make sure that the plugins are owned by nagios
chown -R nagios.nagios /usr/local/nagios/libexec

# compile nrpe
cd /root/nrpe-*
./configure --enable-command-args \
--with-nagios-user=nagios --with-nagios-group=nagios \
--with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib/x86_64-linux-gnu
make all
make install
make install-config
make install-init

# add the nagios server to the nrpe config
sed -i 's/^allowed_hosts=127.0.0.1/allowed_hosts=127.0.0.1,10.100.100.196/g' /usr/local/nagios/etc/nrpe.cfg

# enable and start nrpe
systemctl enable nrpe
systemctl start nrpe
systemctl status nrpe
