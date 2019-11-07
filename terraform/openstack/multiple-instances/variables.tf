variable "count" {
  default = 3
}

# get image name with "openstack image list"
variable "image" {
  default = "<image_name>"
}

# get flavor with "openstack flavor list"
variable "flavor" {
  default = "<flavor>"
}

# get keypair list with "openstack keypair list"
variable "ssh_key_pair" {
  default = "<keypair_name>"
}

# if you're using CentOS image, use "centos", if you're using Ubuntu, use "ubuntu"
variable "ssh_user_name" {
  default = "centos"
}

# most of the time the default is nova, otherwise specify the zone
variable "availability_zone" {
        default = "nova"
}

# default to default but if you're using another security group, change it
variable "security_group" {
        default = "default"
}

# get network with "openstack network list", this is your tenant network and not the external net
variable "network" {
        default  = "tenant-network"
}
