terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
  user_ocid        = var.user_ocid
}

# --- Dados e Namespaces ---
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_ocid
}

# --- Módulos de Infraestrutura ---
module "network" {
  source          = "../../modules/network"
  compartment_id  = var.compartment_ocid
  project_prefix  = var.project_prefix
  vcn_cidr        = "10.0.0.0/16"
  subnet_cidr     = "10.0.1.0/24"
  tags            = var.tags
  ssh_source_cidr = var.ssh_source_cidr
}

module "compute" {
  source              = "../../modules/compute"
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[1].name
  instance_shape      = "VM.Standard.E2.1.Micro"
  project_prefix      = var.project_prefix
  ssh_public_key      = var.ssh_public_key
  subnet_id           = module.network.public_subnet_id
  nsg_id              = module.network.app_nsg_id
  user_data_base64    = base64encode(file("../../../scripts/cloud-init.sh"))
  tags                = var.tags
}

# --- Storage: Frontend ---
resource "oci_objectstorage_bucket" "frontend_bucket" {
  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "${var.project_prefix}-frontend-bucket"
  access_type    = "ObjectReadWithoutList"
  freeform_tags  = var.tags
}

resource "oci_objectstorage_object" "frontend_index" {
  bucket       = oci_objectstorage_bucket.frontend_bucket.name
  namespace    = data.oci_objectstorage_namespace.ns.namespace
  object       = "index.html"
  content_type = "text/html"
  content      = templatefile("../../../frontend/index.html", { api_endpoint = module.compute.public_ip })
  depends_on   = [module.compute]
}

# --- Storage: InsumoPro (Acessível pela VM) ---
resource "oci_objectstorage_bucket" "insumopro_bucket" {
  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "${var.project_prefix}-insumopro"
  access_type    = "NoPublicAccess"
  freeform_tags  = var.tags
}

# --- IAM: Permissões para a VM acessar o Bucket ---
resource "oci_identity_dynamic_group" "backend_dg" {
  compartment_id = var.tenancy_ocid
  name           = "${var.project_prefix}-backend-dg"
  description    = "Grupo para a VM acessar o Object Storage"
  matching_rule  = "ALL {instance.id = '${module.compute.instance_id}'}"
}

resource "oci_identity_policy" "backend_storage_policy" {
  compartment_id = var.compartment_ocid
  name           = "${var.project_prefix}-storage-policy"
  description    = "Permite a VM gerenciar objetos no bucket insumopro"

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.backend_dg.name} to manage objects in compartment id ${var.compartment_ocid} where target.bucket.name='${oci_objectstorage_bucket.insumopro_bucket.name}'"
  ]
}

# --- Outputs ---
output "instance_public_ip" {
  value = module.compute.public_ip
}

output "frontend_url" {
  description = "URL for the frontend hosted in OCI Object Storage."
  value       = "https://objectstorage.${var.region}.oraclecloud.com/n/${data.oci_objectstorage_namespace.ns.namespace}/b/${oci_objectstorage_bucket.frontend_bucket.name}/o/index.html"
}

output "insumopro_bucket_name" {
  value = oci_objectstorage_bucket.insumopro_bucket.name
}

output "ssh_command" {
  value     = "ssh -i ${var.ssh_private_key_path} ubuntu@${module.compute.public_ip}"
  sensitive = true
}
