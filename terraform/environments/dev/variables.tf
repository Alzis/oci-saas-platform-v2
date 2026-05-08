variable "tenancy_ocid" {
  description = "The OCID of the tenancy."
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user."
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint for the API key."
  type        = string
}

variable "private_key_path" {
  description = "The path to the private key for the API."
  type        = string
}

variable "ssh_private_key_path" {
  description = "The path to the SSH private key used to access the compute instance."
  type        = string
}

variable "ssh_public_key" {
  description = "The content of the SSH public key."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "The OCI region."
  type        = string
}

variable "compartment_ocid" {
  description = "The OCID of the compartment to create resources in."
  type        = string
}

variable "project_prefix" {
  description = "A prefix for all resource names."
  type        = string
  default     = "saas-platform"
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default = {
    "ManagedBy" = "Terraform"
    "Project"   = "SaaS-Platform"
  }
}

variable "ssh_source_cidr" {
  description = "The source IP address for SSH access. For security, set this to your own IP address (e.g., '1.2.3.4/32')."
  type        = string
  default     = "0.0.0.0/0"
}