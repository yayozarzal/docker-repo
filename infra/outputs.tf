output "public_ip" {
  value       = oci_core_instance.vm[0].public_ip
  description = "IP pública de la VM 1"
}

output "instance_ocid" {
  value = oci_core_instance.vm[0].id
}

output "subnet_id" {
  value = oci_core_subnet.subnet_public.id
}

output "vcn_id" {
  value = oci_core_vcn.vcn.id
}
