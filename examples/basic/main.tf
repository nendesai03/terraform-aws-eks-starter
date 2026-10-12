provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "terraform-aws-eks-starter"
      Environment = "demo"
      ManagedBy   = "terraform"
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name         = var.cluster_name
  cluster_name = var.cluster_name

  vpc_cidr           = "10.0.0.0/16"
  az_count           = 2
  single_nat_gateway = true
}

module "eks" {
  source = "../../modules/eks"

  cluster_name = var.cluster_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids

  public_access_cidrs = var.public_access_cidrs

  node_instance_types = var.node_instance_types
  node_desired_size   = 2
  node_min_size       = 1
  node_max_size       = 3
}