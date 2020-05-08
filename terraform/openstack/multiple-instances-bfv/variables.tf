# input correct values

variable "instance_name" {
  default = " "
}

variable "qty" {
  default = 1
}

# get image name with "openstack image list"
variable "image" {
  default = " "
}

variable "volume_size" {
  default = " "
}

# get flavor with "openstack flavor list"
variable "flavor_name" {
  default = " "
}

# get keypair list with "openstack keypair list"
variable "ssh_keypair" {
  default = " "
}

# most of the time the default is nova, otherwise specify the zone
variable "availability_zone" {
        default = "nova"
}

# default to default but if you're using another security group, change it
variable "secgroup" {
        default = "default"
}

# get network with "openstack network list", this is your tenant network and not the external net
variable "tenant_network" {
  default  = "tenant-network"
}

# this is your external network, get it with "openstack network list"
variable "external_network" {
  default = "publicnet"
}
