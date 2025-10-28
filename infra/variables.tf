variable "tenancy_ocid"       { type = string }
variable "user_ocid"          { type = string }
variable "fingerprint"        { type = string }
variable "private_key_pem"    { type = string }
variable "region"             { type = string }
variable "compartment_ocid"   { type = string }

variable "ssh_public_key"     { type = string }

# Opciones
variable "open_port_80"   { type = bool default = true }
variable "open_port_3000" { type = bool default = true }
variable "vm_count"       { type = number default = 1 } # 1=una VM (front+back), 2=dos VMs

variable "instance_shape" { type = string default = "VM.Standard.E2.1.Micro" }
