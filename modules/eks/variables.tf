variable "cluster_name" {
  description = "Name of the EKS cluster. Also used as a prefix for related resources."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version. Leave null to use the current AWS default. Check supported versions before pinning."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "ID of the VPC the cluster runs in."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the control plane ENIs and worker nodes."
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Expose the Kubernetes API endpoint publicly."
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Expose the Kubernetes API endpoint inside the VPC."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public API endpoint. Restrict this to your IP range for real use."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_log_types" {
  description = "Control plane log types to send to CloudWatch."
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

variable "log_retention_days" {
  description = "CloudWatch retention for control plane logs."
  type        = number
  default     = 30
}

variable "enable_secrets_encryption" {
  description = "Encrypt Kubernetes secrets with a dedicated KMS key. Cannot be removed once enabled."
  type        = bool
  default     = true
}

variable "cluster_addons" {
  description = "EKS managed add-ons to install."
  type        = list(string)
  default     = ["vpc-cni", "kube-proxy", "coredns"]
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_disk_size" {
  description = "Root volume size (GiB) for worker nodes."
  type        = number
  default     = 20
}

variable "node_desired_size" {
  description = "Initial number of worker nodes. Later changes made by autoscalers are ignored by Terraform."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 4
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}