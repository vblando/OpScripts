resource "openstack_compute_instance_v2" "<instance_name>" {
  count = "${var.count}"
  name = "<instance_name>${count.index + 1}"
  image_name = "${var.image}"
  availability_zone = "${var.availability_zone}"
  flavor_name = "${var.flavor}"
  key_pair = "${var.ssh_key_pair}"
  security_groups = ["${var.security_group}"]
  network {
    name = "${var.network}"
  }
}

# get public network name with "openstack network list"
resource "openstack_networking_floatingip_v2" "instance_fip" {
  count = "${var.count}"
  pool = "public_network"
}

resource "openstack_compute_floatingip_associate_v2" "instance_fip" {
  count = "${var.count}"
  floating_ip = "${element(openstack_networking_floatingip_v2.instance_fip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.<instance_name.*.id, count.index)}"
}
