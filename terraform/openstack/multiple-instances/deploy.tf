  count                         = var.qty
  name                          = format("%s-%02d", var.instance_name, count.index+1)
  availability_zone             = var.availability_zone
  flavor_name                   = var.flavor_name
  key_pair                      = var.ssh_keypair
  security_groups               = [var.secgroup]
  image_name                    = var.image
  network {
    name                        = var.tenant_network
  }
}

resource "openstack_networking_floatingip_v2" "instance_fip" {
  count                         = var.qty
  pool                          = var.external_network
}

resource "openstack_compute_floatingip_associate_v2" "instance_fip" {
  count                         = var.qty
  floating_ip                   = "${openstack_networking_floatingip_v2.instance_fip.*.address[count.index]}"
  instance_id                   = "${openstack_compute_instance_v2.Instance.*.id[count.index]}"
}
