variable "location" {
  description = "Azure region"
  type        = string
}

variable "rg_name" {
  description = "Resource group name"
  type        = string
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
}

variable "dns_prefix" {
  description = "AKS DNS prefix"
  type        = string
}

variable "acr_name" {
  description = "Azure Container Registry name"
  type        = string
}

variable "node_count" {
  description = "Node count if autoscaling disabled"
  type        = number
  default     = 1
}

variable "vm_size" {
  description = "VM size for node pool"
  type        = string
}
