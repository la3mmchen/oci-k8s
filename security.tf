resource "oci_core_network_security_group" "kube" {
  compartment_id = oci_identity_compartment.k8s.id
  vcn_id         = oci_core_vcn.k8s.id
  display_name   = "kube-ingress-rules"
}

resource "oci_core_network_security_group_security_rule" "kube-egress-all" {
  network_security_group_id = oci_core_network_security_group.kube.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
}
