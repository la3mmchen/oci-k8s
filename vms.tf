resource "oci_core_instance" "instance" {
  availability_domain = data.oci_identity_availability_domain.az.name
  compartment_id      = oci_identity_compartment.k8s.id
  display_name        = "k8s-0"
  shape               = "VM.Standard.A1.Flex"

  source_details {
    source_type = "image"
    source_id   = "ocid1.image.oc1.uk-london-1.aaaaaaaablhbhcs6erb66qu7ofkntsdzgstffnh7g3l34ovc53uum7vx6oca" # Ubuntu 20
  }

  create_vnic_details {
    subnet_id                 = oci_core_subnet.k8s-net.id
    display_name              = "k8s-network"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = "k8s-0"
    nsg_ids                   = [oci_core_network_security_group.kube.id]
  }

  shape_config {
    ocpus         = 4
    memory_in_gbs = 24
  }

  metadata = {
    ssh_authorized_keys = file("~/.ssh/id_rsa.pub")
    user_data           = "${base64encode(templatefile(format("provision-%s.tpl",var.flavor), { hostname = "k8s-0", domain = "k8s.local" }))}"
  }

  lifecycle {
    create_before_destroy = false
  }
}

