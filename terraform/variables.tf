variable "resource_group_name" {
  default = "rg-github"
}

variable "location" {
  default = "East US"
}

variable "aks_name" {
  default = "aks-github"
}

variable "node_count" {
  default = 1
}

variable "node_vm_size" {
  default = "Standard_DS2_v2"
}
