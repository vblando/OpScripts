resource "openstack_compute_instance_v2" "Instance" {
  count 			= var.qty
  name 				= format("%s-%02d", var.instance_name, count.index+1)
  availability_zone 		= var.availability_zone
  flavor_name  			= var.flavor_name
  key_pair 			= var.ssh_keypair
  security_groups 		= [var.secgroup]
  network {
    name 			= var.tenant_network
  }
  block_device {
    uuid                  	= var.image
    source_type           	= "image"
    volume_size           	= var.volume_size
    boot_index            	= 0
    destination_type      	= "volume"
    delete_on_termination 	= true
  }
}

resource "openstack_networking_floatingip_v2" "instance_fip" {
  count 			= var.qty
  pool 				= var.external_network
}

resource "openstack_compute_floatingip_associate_v2" "instance_fip" {
  count 			= var.qty
  floating_ip 			= "${openstack_networking_floatingip_v2.instance_fip.*.address[count.index]}"
  instance_id 			= "${openstack_compute_instance_v2.Instance.*.id[count.index]}"
}
