/*
 * This example demonstrates how to spin up an Oracle Linux instance and get its public ip.
 */

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "private_key_password" {}

variable "compartment_ocid" {}
variable "ssh_public_key" {}
variable "ssh_private_key" {}
variable "region" {}


provider "oci" {
  tenancy_ocid = "${var.tenancy_ocid}"
  user_ocid = "${var.user_ocid}"
  fingerprint = "${var.fingerprint}"
  private_key_path = "${var.private_key_path}"
  private_key_password = "${var.private_key_password}"
  region = "${var.region}"
}

data "oci_identity_availability_domains" "ADs" {
    compartment_id = "${var.tenancy_ocid}"
}


/* Network */

resource "oci_core_virtual_network" "vcn1" {
  cidr_block     = "10.1.0.0/16"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "vcn1"
  dns_label      = "vcn1"
}

#AD1
resource "oci_core_subnet" "subnet1" {
    availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
    cidr_block = "10.1.20.0/24"
    display_name = "subnet1"
    dns_label = "subnet1"
    security_list_ids = ["${oci_core_virtual_network.vcn1.default_security_list_id}"]
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.vcn1.id}"
    route_table_id = "${oci_core_route_table.routetable1.id}"
    dhcp_options_id = "${oci_core_virtual_network.vcn1.default_dhcp_options_id}"

    provisioner "local-exec" {
        command = "sleep 5"
    }
}

 resource "oci_core_internet_gateway" "internetgateway1" {
    compartment_id = "${var.compartment_ocid}"
    display_name = "internetgateway1"
    vcn_id = "${oci_core_virtual_network.vcn1.id}"
}


 resource "oci_core_route_table" "routetable1" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.vcn1.id}"
    display_name = "Default Route Table for vcn1"
    route_rules {
        cidr_block = "0.0.0.0/0"
        network_entity_id = "${oci_core_internet_gateway.internetgateway1.id}"
    }
}

/* Instances */

data "oci_core_images" "image-list" {
  compartment_id = "${var.compartment_ocid}"
  operating_system = "Oracle Linux"
  operating_system_version = "7.4"
}

resource "oci_core_instance" "instance1" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "tf-server01"
  image = "${lookup(data.oci_core_images.image-list.images[0], "id")}"
  shape = "VM.Standard1.1"
  subnet_id = "${oci_core_subnet.subnet1.id}"
  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
  }
}


output "InstancePublicIP" {
  value = ["${oci_core_instance.instance1.public_ip}"]
}
