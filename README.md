# terraform-aws-eks-starter

Reusable Terraform modules for a production-style AWS EKS cluster:
VPC with public/private subnets, EKS control plane, managed node group,
and IAM Roles for Service Accounts (IRSA).

> **Status:** work in progress. Modules are being built and tested step by step.

## What's included

- `modules/vpc`: VPC, public and private subnets across AZs, NAT, route tables
- `modules/eks`: EKS cluster, managed node group, OIDC provider, IAM roles
- `examples/basic`: end-to-end example wiring both modules together

## Requirements

- Terraform >= 1.5
- AWS CLI configured with permissions to create VPC, EKS, and IAM resources
- `kubectl` to interact with the cluster

## Usage

*(Coming once the modules are tested.)*

## Cost warning

An EKS cluster is not free-tier. Expect roughly the EKS control plane
(~$0.10/hour), EC2 nodes, and NAT gateway charges. Run `terraform destroy`
when you're done testing.

## License

MIT