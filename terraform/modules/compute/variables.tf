variable "tenancy_ocid" {
  type        = string
  description = "The OCID of the tenancy."
}

variable "user_ocid" {
  type        = string
  description = "The OCID of the user."
}

variable "fingerprint" {
  type        = string
  description = "The fingerprint for the API key."
}

variable "private_key_path" {
  type        = string
  description = "The path to the private key for the API."
}

variable "compartment_ocid" {
  type        = string
  description = "The OCID of the compartment to create resources in."
}

variable "ssh_public_key" {
  type        = string
  description = "The SSH public key to use for the compute instance."
  sensitive   = true
}
variable "ssh_private_key_path" {
  type        = string
  description = "The path to the SSH private key used to access the compute instance."
}

variable "region" {
  type        = string
  description = "The OCI region."
}