resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_id
  cidr_block     = var.vcn_cidr
  display_name   = "${var.project_prefix}-vcn"
  dns_label      = replace(var.project_prefix, "-", "")
  freeform_tags  = var.tags
}

resource "oci_core_internet_gateway" "gw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_prefix}-igw"
  enabled        = true
  freeform_tags  = var.tags
}

resource "oci_core_route_table" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_prefix}-rt"
  freeform_tags  = var.tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.gw.id
  }
}

resource "oci_core_subnet" "public" {
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_vcn.main.id
  cidr_block          = var.subnet_cidr
  display_name        = "${var.project_prefix}-public-subnet"
  dns_label           = "public"
  route_table_id      = oci_core_route_table.main.id
  prohibit_public_ip_on_vnic = false
  freeform_tags       = var.tags
}

resource "oci_core_network_security_group" "app_nsg" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_prefix}-app-nsg"
  freeform_tags  = var.tags
}

# Regra para acesso SSH
resource "oci_core_network_security_group_security_rule" "allow_ssh" {
  network_security_group_id = oci_core_network_security_group.app_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = var.ssh_source_cidr
  source_type               = "CIDR_BLOCK"
  description               = "Allow SSH access"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

# Regra para acesso Web (HTTP/HTTPS)
resource "oci_core_network_security_group_security_rule" "allow_web" {
  network_security_group_id = oci_core_network_security_group.app_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  description               = "Allow HTTP and HTTPS access"
  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
  # Adicione a porta 443 quando for implementar SSL
}