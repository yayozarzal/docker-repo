terraform {
  required_version = ">= 1.6.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.12"
    }
  }
  # Para demo: backend local. Recomendado: Terraform Cloud u OCI Object Storage.
  # backend "local" {}
}

provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  user_ocid    = var.user_ocid
  fingerprint  = var.fingerprint
  private_key  = var.private_key_pem
  region       = var.region
}
