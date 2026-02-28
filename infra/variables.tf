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
  description = "Initial node count"
  type        = number
}

variable "vm_size" {
  description = "VM size for AKS nodes"
  type        = string
}

# Recommended additions for autoscaling
variable "min_node_count" {
  description = "Minimum nodes for autoscaling"
  type        = number
}

variable "max_node_count" {
  description = "Maximum nodes for autoscaling"
  type        = number
}
