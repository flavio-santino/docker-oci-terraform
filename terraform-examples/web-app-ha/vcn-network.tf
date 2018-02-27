#This is the Network Configuration for your Web Servers, Database and Bastion/NAT 

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "private_key_password" {}
variable "compartment_ocid" {}
variable "ssh_public_key" {}
variable "region" {}

variable "vcn_cidr" {
  default = "10.0.0.0/16"
}

variable "private_subnet_web01" {
  default = "10.0.1.0/24"
}

variable "private_subnet_web02" {
  default = "10.0.2.0/24"
}

variable "private_subnet_db" {
  default = "10.0.10.0/24"
}

variable "public_subnet_lb01" {
  default = "10.0.20.0/24"
}

variable "public_subnet_lb02" {
  default = "10.0.21.0/24"
}

variable "public_subnet_bastion_nat" {
  default = "10.0.30.0/24"
}

data "oci_identity_availability_domains" "ADs" {
  compartment_id = "${var.tenancy_ocid}"
}

provider "oci" {
  tenancy_ocid         = "${var.tenancy_ocid}"
  user_ocid            = "${var.user_ocid}"
  fingerprint          = "${var.fingerprint}"
  private_key_path     = "${var.private_key_path}"
  private_key_password = "${var.private_key_password}"
  region               = "${var.region}"
}

# This is the main VCN

resource "oci_core_virtual_network" "Prod_VCN" {
  cidr_block     = "${var.vcn_cidr}"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "prod-vcn"
}

#Internet Gateway and Security Rules for Public Subnets

resource "oci_core_internet_gateway" "Public_IG" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "Public_IG"
  vcn_id         = "${oci_core_virtual_network.Prod_VCN.id}"
}

resource "oci_core_route_table" "ProdRouteTable" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.Prod_VCN.id}"
  display_name   = "ProdRouteTable"

  route_rules {
    cidr_block        = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.Public_IG.id}"
  }
}

resource "oci_core_security_list" "PublicSecurityList" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "PublicSecurityList"
  vcn_id         = "${oci_core_virtual_network.Prod_VCN.id}"

  egress_security_rules = [{
    protocol    = "all"
    destination = "0.0.0.0/0"
  }]

  ingress_security_rules = [{
    protocol = "6"

    tcp_options {
      "min" = 22
      "max" = 22
    }

    source = "0.0.0.0/0"
  }]

  ingress_security_rules = [{
    protocol = "all"
    source = "${var.vcn_cidr}"
  }]
}

# Route table and Security Lists for Private Subnets

resource "oci_core_security_list" "DBPrivateSecurityList" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "DBPrivateSecurityList"
  vcn_id         = "${oci_core_virtual_network.Prod_VCN.id}"

  egress_security_rules = [{
    protocol    = "all"
    destination = "0.0.0.0/0"
  }]

  ingress_security_rules = [{
    protocol = "6"

    tcp_options {
      "max" = 22
      "min" = 22
    }

    source = "${var.public_subnet_bastion_nat}"
  }]

  ingress_security_rules = [{
    protocol = "6"

    tcp_options {
      "max" = 3306
      "min" = 3306
    }

    source = "${var.private_subnet_web01}"
  }]

  ingress_security_rules = [{
    protocol = "6"

    tcp_options {
      "max" = 3306
      "min" = 3306
    }

    source = "${var.private_subnet_web02}"
  }]
}

resource "oci_core_security_list" "WebPrivateSecurityList" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "WebPrivateSecurityList"
  vcn_id         = "${oci_core_virtual_network.Prod_VCN.id}"

  egress_security_rules = [{
    protocol    = "all"
    destination = "0.0.0.0/0"
  }]

  ingress_security_rules = [{
    protocol = "6"

    tcp_options {
      "max" = 22
      "min" = 22
    }

    source = "${var.public_subnet_bastion_nat}"
  }]
}

resource "oci_core_route_table" "PrivateRouteTable" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.Prod_VCN.id}"
  display_name   = "PrivateRouteTable"

  route_rules {
    cidr_block = "0.0.0.0/0"

    #        network_entity_id = "${oci_core_private_ip.NatInstancePrivateIP.id}"
    network_entity_id = "${lookup(data.oci_core_private_ips.myPrivateIPs.private_ips[0],"id")}"
  }
}

# This the Bastion NAT Public Subnet

resource "oci_core_subnet" "BastionSubnet" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  cidr_block          = "${var.public_subnet_bastion_nat}"
  display_name        = "public_subnet_bastion_nat"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.Prod_VCN.id}"
  route_table_id      = "${oci_core_route_table.ProdRouteTable.id}"
  security_list_ids   = ["${oci_core_security_list.PublicSecurityList.id}"]
  dhcp_options_id     = "${oci_core_virtual_network.Prod_VCN.default_dhcp_options_id}"
}

# Gets a list of VNIC attachments on the Bastion-NAT instance
data "oci_core_vnic_attachments" "NatInstanceVnics" {
  compartment_id      = "${var.compartment_ocid}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  instance_id         = "${oci_core_instance.Bastion_NAT_Instance.id}"
}

# Gets the OCID of the first (default) vNIC on the Bastion-NAT instance
data "oci_core_vnic" "NatInstanceVnic" {
  vnic_id = "${lookup(data.oci_core_vnic_attachments.NatInstanceVnics.vnic_attachments[0],"vnic_id")}"
}

data "oci_core_private_ips" "myPrivateIPs" {
  ip_address = "${data.oci_core_vnic.NatInstanceVnic.private_ip_address}"
  subnet_id  = "${oci_core_subnet.BastionSubnet.id}"
}

#This is the Web and Database Private Subnets
resource "oci_core_subnet" "Private_Web_Subnet01" {
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  cidr_block                 = "${var.private_subnet_web01}"
  display_name               = "private_subnet_web01"
  compartment_id             = "${var.compartment_ocid}"
  vcn_id                     = "${oci_core_virtual_network.Prod_VCN.id}"
  route_table_id             = "${oci_core_route_table.PrivateRouteTable.id}"
  security_list_ids          = ["${oci_core_security_list.WebPrivateSecurityList.id}"]
  dhcp_options_id            = "${oci_core_virtual_network.Prod_VCN.default_dhcp_options_id}"
  prohibit_public_ip_on_vnic = "true"
}

resource "oci_core_subnet" "Private_Web_Subnet02" {
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[1],"name")}"
  cidr_block                 = "${var.private_subnet_web02}"
  display_name               = "private_subnet_web02"
  compartment_id             = "${var.compartment_ocid}"
  vcn_id                     = "${oci_core_virtual_network.Prod_VCN.id}"
  route_table_id             = "${oci_core_route_table.PrivateRouteTable.id}"
  security_list_ids          = ["${oci_core_security_list.WebPrivateSecurityList.id}"]
  dhcp_options_id            = "${oci_core_virtual_network.Prod_VCN.default_dhcp_options_id}"
  prohibit_public_ip_on_vnic = "true"
}

resource "oci_core_subnet" "Private_Database01" {
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[2],"name")}"
  cidr_block                 = "${var.private_subnet_db}"
  display_name               = "private_subnet_db"
  compartment_id             = "${var.compartment_ocid}"
  vcn_id                     = "${oci_core_virtual_network.Prod_VCN.id}"
  route_table_id             = "${oci_core_route_table.PrivateRouteTable.id}"
  security_list_ids          = ["${oci_core_security_list.DBPrivateSecurityList.id}"]
  dhcp_options_id            = "${oci_core_virtual_network.Prod_VCN.default_dhcp_options_id}"
  prohibit_public_ip_on_vnic = "true"
}

# Load Balancer Public Subnets

resource "oci_core_subnet" "LBSunet01" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  cidr_block          = "${var.public_subnet_lb01}"
  display_name        = "public_subnet_lb01"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.Prod_VCN.id}"
  route_table_id      = "${oci_core_route_table.ProdRouteTable.id}"
  security_list_ids   = ["${oci_core_security_list.PublicSecurityList.id}"]
  dhcp_options_id     = "${oci_core_virtual_network.Prod_VCN.default_dhcp_options_id}"
}

resource "oci_core_subnet" "LBSunet02" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[1],"name")}"
  cidr_block          = "${var.public_subnet_lb02}"
  display_name        = "public_subnet_lb02"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.Prod_VCN.id}"
  route_table_id      = "${oci_core_route_table.ProdRouteTable.id}"
  security_list_ids   = ["${oci_core_security_list.PublicSecurityList.id}"]
  dhcp_options_id     = "${oci_core_virtual_network.Prod_VCN.default_dhcp_options_id}"
}
