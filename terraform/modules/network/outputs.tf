output "public_subnet_id" {
  description = "The OCID of the public subnet."
  value       = oci_core_subnet.public.id
}

output "app_nsg_id" {
  description = "The OCID of the application Network Security Group."
  value       = oci_core_network_security_group.app_nsg.id
}