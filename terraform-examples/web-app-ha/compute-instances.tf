/* Web Servers and Database instances */

variable "OS_Image" {
  default = "Oracle-Linux-7.4-2018.01.20-0"
}

variable "DatabaseShape" {
  default = "VM.Standard1.2"
}

variable "WebShape" {
  default = "VM.Standard2.1"
}

variable "BastionShape" {
  default = "VM.Standard1.2"
}

data "oci_core_images" "OS_image_ocid" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.OS_Image}"
}

resource "oci_core_instance" "web01" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "web-server-01"
  image               = "${lookup(data.oci_core_images.OS_image_ocid.images[0], "id")}"
  shape               = "${var.WebShape}"

  create_vnic_details {
    subnet_id        = "${oci_core_subnet.Private_Web_Subnet01.id}"
    assign_public_ip = false
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
  }
}

resource "oci_core_instance" "web02" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "web-server-02"
  image               = "${lookup(data.oci_core_images.OS_image_ocid.images[0], "id")}"
  shape               = "${var.WebShape}"

  create_vnic_details {
    subnet_id        = "${oci_core_subnet.Private_Web_Subnet02.id}"
    assign_public_ip = false
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
  }
}

resource "oci_core_instance" "Database" {
  count               = "1"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[2],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "db-server-${count.index}"
  image               = "${lookup(data.oci_core_images.OS_image_ocid.images[0], "id")}"
  shape               = "${var.DatabaseShape}"

  create_vnic_details {
    subnet_id        = "${oci_core_subnet.Private_Database01.id}"
    assign_public_ip = false
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
  }
}

resource "oci_core_instance" "Bastion_NAT_Instance" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Bastion-NAT-Instance"
  image               = "${lookup(data.oci_core_images.OS_image_ocid.images[0], "id")}"
  shape               = "${var.BastionShape}"

  create_vnic_details {
    subnet_id              = "${oci_core_subnet.BastionSubnet.id}"
    skip_source_dest_check = true
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data           = "${base64encode(file("user_data.tpl"))}"
  }

  timeouts {
    create = "10m"
  }
}
