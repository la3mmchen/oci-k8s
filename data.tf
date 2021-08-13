data "oci_identity_availability_domain" "az" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}
