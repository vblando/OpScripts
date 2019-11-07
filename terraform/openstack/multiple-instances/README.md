
## Sample script for deploying multiple instances 

#### Make sure you load your OpenStack Credentials before proceeding

```$ source </path/to/your/openstack_creds.rc>```

#### Initialize Terraform 

```$ terraform init ```

#### Double check your configs

``` $ terraform plan ```

#### Deploy

``` $ terraform apply ```

#### Once done, check if the instance(s) are deployed without error and you can connect to it via SSH

    openstack server list
    ssh centos@<floating_ip_of_the_instance>



