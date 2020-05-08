#!/bin/bash

# assuming that your iDRAC is still using the default username and password
raccmd="racadm -u root -p calvin --nocertwarn"

# create a hosts file with the IP addresses of Dell iDRAC, 1 IP per line
for host in $(cat idrac-hosts)
  do
    $raccmd -r $host config -g cfgldap -o cfgLdapEnable 1
    $raccmd -r $host config -g cfgldap -o cfgLdapServer your_ldap_server_fqdn_or_ip_address
    $raccmd -r $host config -g cfgldap -o cfgLdapPort 636
    $raccmd -r $host config -g cfgldap -o cfgLdapBaseDN your_ldap_base_dn
    $raccmd -r $host config -g cfgldap -o cfgLdapUserAttribute your_ldap_attribute_used
    $raccmd -r $host config -g cfgldap -o cfgLdapGroupAttributeIsDN 1
    $raccmd -r $host config -g cfgldap -o cfgLdapBindDN your_ldap_bind_address
    $raccmd -r $host config -g cfgldap -o cfgLdapBindPassword your_ldap_bind_password
    $raccmd -r $host config -g cfgldap -o cfgLdapCertValidationEnable 0
    $raccmd -r $host config -g cfgldaprolegroup -i 1 -o cfgLdapRoleGroupDN your_ldap_role_group_dn
    $raccmd -r $host config -g cfgldaprolegroup -i 1 -o cfgLdapRoleGroupPrivilege 0x000001ff
done
