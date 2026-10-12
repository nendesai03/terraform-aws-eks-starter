variable "name" {
  description = "Name prefix applied to all VPC resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Must be a /16, because subnet ranges are derived from it."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && tonumber(split("/", var.vpc_cidr)[1]) == 16
    error_message = "vpc_cidr must be a valid IPv4 CIDR with a /16 prefix."
  }
}

variable "az_count" {
  description = "Number of Availability Zones to spread subnets across (2-6)."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 6
    error_message = "az_count must be between 2 and 6."
  }
}

variable "enable_nat_gateway" {
  description = "Create NAT gateway(s) so private subnets can reach the internet."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway (cheaper) instead of one per AZ (highly available)."
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "EKS cluster name. If set, subnets get the kubernetes.io/cluster/<name> tag."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}