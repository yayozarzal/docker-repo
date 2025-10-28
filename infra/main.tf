# === Imagen Ubuntu 22.04 más reciente para la región ===
data "oci_core_images" "ubuntu_2204" {
  compartment_id = var.compartment_ocid
  operating_system = "Canonical Ubuntu"
  operating_system_version = "22.04"
  sort_by = "TIMECREATED"
  sort_order = "DESC"
  shape = var.instance_shape
}

locals {
  ubuntu_image_id = data.oci_core_images.ubuntu_2204.images[0].id
  ad_index = 0 # AD-1
}

# === Red ===
resource "oci_core_vcn" "vcn" {
  cidr_block     = "10.10.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "vcn-task-demo"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  display_name   = "igw"
  vcn_id         = oci_core_vcn.vcn.id
  enabled        = true
}

resource "oci_core_route_table" "rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "rt-to-inet"
  route_rules {
    network_entity_id = oci_core_internet_gateway.igw.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "sl-public"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  # SSH 22
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP 80
  dynamic "ingress_security_rules" {
    for_each = var.open_port_80 ? [1] : []
    content {
      protocol = "6"
      source   = "0.0.0.0/0"
      tcp_options {
        min = 80
        max = 80
      }
    }
  }

  # API 3000
  dynamic "ingress_security_rules" {
    for_each = var.open_port_3000 ? [1] : []
    content {
      protocol = "6"
      source   = "0.0.0.0/0"
      tcp_options {
        min = 3000
        max = 3000
      }
    }
  }
}

resource "oci_core_subnet" "subnet_public" {
  cidr_block        = "10.10.1.0/24"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.vcn.id
  display_name      = "subnet-public"
  route_table_id    = oci_core_route_table.rt.id
  security_list_ids = [oci_core_security_list.sl.id]
  prohibit_public_ip_on_vnic = false
}

# === cloud-init con Docker + Compose + despliegue ===
data "template_file" "cloud_init" {
  template = file("${path.module}/cloud-init.tpl")
}

# 1 VM que corre frontend+backend. (Si quieres 2: duplica este bloque con nombres distintos)
resource "oci_core_instance" "vm" {
  count               = var.vm_count
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[local.ad_index].name
  compartment_id      = var.compartment_ocid
  shape               = var.instance_shape
  display_name        = "taskdemo-${count.index + 1}"

  create_vnic_details {
    subnet_id        = oci_core_subnet.subnet_public.id
    assign_public_ip = true
    display_name     = "vnic-taskdemo-${count.index + 1}"
  }

  source_details {
    source_type = "image"
    source_id   = local.ubuntu_image_id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(templatefile("${path.module}/cloud-init.tpl", {}))
  }
}

# Necesario para availability domain
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}
