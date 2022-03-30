resource "oci_identity_compartment" "k8s" {
  compartment_id = "ocid1.tenancy.oc1..aaaaaaaap266ftquxuhkoyxmwgs5upoun3zlfmphl5rhirpjxxmatq6tsk7q"
  description    = "K8s stuff"
  name           = "k8s-stuff"
}

resource "oci_core_vcn" "k8s" {
  cidr_blocks    = ["10.0.0.0/16"]
  compartment_id = oci_identity_compartment.k8s.id
  display_name   = "k8s"
  dns_label      = "kube"

  lifecycle {
    create_before_destroy = false
  }
}

resource "oci_core_subnet" "k8s-net" {
  availability_domain = data.oci_identity_availability_domain.az.name
  cidr_block          = "10.0.1.0/24"
  display_name        = "k8s-network"
  dns_label           = "kube"
  security_list_ids   = [oci_core_vcn.k8s.default_security_list_id]
  compartment_id      = oci_identity_compartment.k8s.id
  vcn_id              = oci_core_vcn.k8s.id
  route_table_id      = oci_core_vcn.k8s.default_route_table_id
  dhcp_options_id     = oci_core_vcn.k8s.default_dhcp_options_id

  provisioner "local-exec" {
    command = "sleep 5"
  }
}


resource "oci_core_internet_gateway" "kube-inet-gw" {
  compartment_id = oci_identity_compartment.k8s.id
  display_name   = "KubeInetGw"
  vcn_id         = oci_core_vcn.k8s.id
}

resource "oci_core_default_route_table" "default_route_table" {
  manage_default_resource_id = oci_core_vcn.k8s.default_route_table_id
  display_name               = "DefaultRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.kube-inet-gw.id
  }
}