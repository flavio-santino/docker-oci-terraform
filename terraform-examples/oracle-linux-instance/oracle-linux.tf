/*
 * This example demonstrates how to spin up two Oracle Linux instances and get its public ip.
 */

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "private_key_password" {}
variable "compartment_ocid" {}
variable "ssh_public_key" {}
variable "region" {}

variable "OS_Image" {
  default = "Oracle-Linux-7.4-2018.01.20-0"
}

provider "oci" {
  tenancy_ocid         = "${var.tenancy_ocid}"
  user_ocid            = "${var.user_ocid}"
  fingerprint          = "${var.fingerprint}"
  private_key_path     = "${var.private_key_path}"
  private_key_password = "${var.private_key_password}"
  region               = "${var.region}"
}

data "oci_identity_availability_domains" "ADs" {
  compartment_id = "${var.tenancy_ocid}"
}

data "oci_core_images" "OS_image_ocid" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.OS_Image}"
}

/* Network */

resource "oci_core_virtual_network" "vcn1" {
  cidr_block     = "10.1.0.0/16"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "vcn1"
  dns_label      = "vcn1"
}

#AD1 subnet 01
resource "oci_core_subnet" "subnet1" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  cidr_block          = "10.1.20.0/24"
  display_name        = "subnet1"
  dns_label           = "subnet1"
  security_list_ids   = ["${oci_core_virtual_network.vcn1.default_security_list_id}"]
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.vcn1.id}"
  route_table_id      = "${oci_core_route_table.routetable1.id}"
  dhcp_options_id     = "${oci_core_virtual_network.vcn1.default_dhcp_options_id}"

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_core_internet_gateway" "internetgateway1" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "internetgateway1"
  vcn_id         = "${oci_core_virtual_network.vcn1.id}"
}

resource "oci_core_route_table" "routetable1" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.vcn1.id}"
  display_name   = "Default Route Table for vcn1"

  route_rules {
    cidr_block        = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.internetgateway1.id}"
  }
}

/* Instances */

resource "oci_core_instance" "instances" {
  count               = "2"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "tf-server-${count.index}"
  image               = "${lookup(data.oci_core_images.OS_image_ocid.images[0], "id")}"
  shape               = "VM.Standard1.1"
  subnet_id           = "${oci_core_subnet.subnet1.id}"

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
  }
}

output "InstancePublicIP" {
  value = ["${oci_core_instance.instances.*.public_ip}"]
}
