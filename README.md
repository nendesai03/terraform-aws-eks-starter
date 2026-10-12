# terraform-aws-eks-starter

[![Terraform Validate](https://github.com/nendesai03/terraform-aws-eks-starter/actions/workflows/terraform-validate.yml/badge.svg)](https://github.com/nendesai03/terraform-aws-eks-starter/actions/workflows/terraform-validate.yml)
![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-844FBA.svg?logo=terraform)
![AWS Provider](https://img.shields.io/badge/AWS%20Provider-%3E%3D5.0-orange.svg?logo=amazon-aws)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

Production-ready, reusable Terraform modules for provisioning an Amazon Elastic Kubernetes Service (EKS) cluster with a purpose-built Virtual Private Cloud (VPC), managed node groups, and IAM Roles for Service Accounts (IRSA).

---

## Architecture Overview

```
                      +------------------------------------+
                      |            AWS VPC /16             |
                      |                                    |
  Internet Gateway <--+-- Public Subnets (/24 per AZ)      |
                      |   - NAT Gateway(s)                 |
                      |   - Public ALBs / NLBs             |
                      |                                    |
       NAT Gateway <--+-- Private Subnets (/20 per AZ)     |
                      |   - EKS Managed Node Group         |
                      |   - Internal Load Balancers        |
                      |   - Cluster ENIs                   |
                      +-----------------+------------------+
                                        |
                      +-----------------v------------------+
                      |         AWS EKS Control Plane      |
                      | - KMS Envelope Encryption (Secrets)|
                      | - CloudWatch Audit & API Logs      |
                      | - EKS Access Entries               |
                      | - IAM OIDC Provider (IRSA)         |
                      | - Add-ons: vpc-cni, kube-proxy,    |
                      |            coredns                 |
                      +------------------------------------+
```

### Key Features

- **Networking (`modules/vpc`)**:
  - Multi-AZ VPC deployment (2 to 6 Availability Zones).
  - Public subnets for load balancers (`kubernetes.io/role/elb = 1`).
  - Private subnets for nodes and workloads (`kubernetes.io/role/internal-elb = 1`).
  - Flexible NAT Gateway deployment: single NAT (cost-optimized) or one per AZ (high availability).
- **Control Plane Security & Reliability (`modules/eks`)**:
  - AWS KMS customer-managed key for Kubernetes secrets envelope encryption with 7-day deletion window and annual rotation.
  - CloudWatch Log Group with configurable retention for `api`, `audit`, and `authenticator` logs.
  - Native EKS Access Entries (`API_AND_CONFIG_MAP`) enabled by default.
  - Configurable private and public API server endpoints with CIDR whitelisting.
- **Worker Nodes**:
  - AWS-managed node groups located securely in private subnets with auto-scaling boundaries.
  - Instance lifecycle configuration ignores manual/HPA/Karpenter scaling updates to prevent Terraform state drifts.
  - On-Demand and Spot instances supported.
- **IAM Roles for Service Accounts (IRSA)**:
  - Automated IAM OIDC Identity Provider setup for fine-grained, least-privilege pod permissions.
- **Essential Managed Add-ons**:
  - Pre-configured `vpc-cni`, `kube-proxy`, and `coredns`.

---

## Repository Layout

```text
.
├── .github/
│   └── workflows/
│       └── terraform-validate.yml  # GitHub Actions CI matrix validation
├── modules/
│   ├── vpc/                        # VPC, subnets, NAT gateways, route tables
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   └── eks/                        # EKS cluster, node groups, KMS, OIDC, add-ons
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
├── examples/
│   └── basic/                      # End-to-end root module wiring VPC + EKS
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars.example
│       └── versions.tf
├── LICENSE
└── README.md
```

---

## Prerequisites

Before deploying, ensure you have installed and configured:

- [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.5.0`
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with credentials having permissions for VPC, EC2, IAM, KMS, and EKS resources (`aws configure` or AWS SSO)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) matching your target Kubernetes version

---

## Quickstart

Deploy a complete working cluster using the included basic example:

### 1. Clone the repository and navigate to the basic example

```bash
git clone https://github.com/nendesai03/terraform-aws-eks-starter.git
cd terraform-aws-eks-starter/examples/basic
```

### 2. Configure variables

Copy the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your settings, specifically restricting `public_access_cidrs` to your public IP address:

```hcl
region       = "us-east-1"
cluster_name = "eks-starter-demo"

# Find your public IP via: curl ifconfig.me
public_access_cidrs = ["203.0.113.10/32"]

node_instance_types = ["t3.medium"]
```

### 3. Initialize and validate

```bash
terraform init
terraform fmt -check
terraform validate
```

### 4. Review the plan and apply

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

> **Note:** Provisioning an EKS cluster with managed node groups and KMS keys typically takes 10–15 minutes.

### 5. Access the cluster

Once Terraform completes, update your local `kubeconfig`:

```bash
aws eks update-kubeconfig --name eks-starter-demo --region us-east-1
```

Verify cluster access and nodes:

```bash
kubectl get nodes -o wide
kubectl get pods -A
```

### 6. Clean up

To destroy all provisioned infrastructure and avoid ongoing cloud costs:

```bash
terraform destroy -auto-approve
```

---

## Module Usage

### VPC Module (`modules/vpc`)

```hcl
module "vpc" {
  source = "github.com/nendesai03/terraform-aws-eks-starter//modules/vpc"

  name         = "my-cluster"
  cluster_name = "my-cluster"
  vpc_cidr     = "10.0.0.0/16"
  az_count     = 3

  enable_nat_gateway = true
  single_nat_gateway = true # Set false for one NAT per AZ in production

  tags = {
    Environment = "production"
  }
}
```

#### Inputs

| Name | Description | Type | Default | Required |
|:-----|:------------|:-----|:--------|:--------:|
| `name` | Name prefix for VPC resources | `string` | - | yes |
| `vpc_cidr` | IPv4 CIDR for the VPC (must be a `/16`) | `string` | `"10.0.0.0/16"` | no |
| `az_count` | Number of Availability Zones (2 to 6) | `number` | `3` | no |
| `enable_nat_gateway` | Create NAT Gateway(s) for private subnet egress | `bool` | `true` | no |
| `single_nat_gateway` | Use one shared NAT (cheaper) vs. one per AZ (HA) | `bool` | `true` | no |
| `cluster_name` | EKS cluster name for subnet discovery tags | `string` | `""` | no |
| `tags` | Map of tags applied to all resources | `map(string)` | `{}` | no |

#### Outputs

| Name | Description |
|:-----|:------------|
| `vpc_id` | ID of the VPC |
| `vpc_cidr_block` | CIDR block of the VPC |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs (pass to EKS nodes) |
| `availability_zones` | List of AZ names used |
| `nat_public_ips` | Elastic IP addresses of the NAT Gateway(s) |

---

### EKS Module (`modules/eks`)

```hcl
module "eks" {
  source = "github.com/nendesai03/terraform-aws-eks-starter//modules/eks"

  cluster_name = "my-cluster"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids

  public_access_cidrs = ["203.0.113.10/32"]

  node_instance_types = ["t3.medium"]
  node_desired_size   = 2
  node_min_size       = 1
  node_max_size       = 5

  enable_secrets_encryption = true

  tags = {
    Environment = "production"
  }
}
```

#### Inputs

| Name | Description | Type | Default | Required |
|:-----|:------------|:-----|:--------|:--------:|
| `cluster_name` | Name of the EKS cluster and resource prefix | `string` | - | yes |
| `vpc_id` | VPC ID where cluster resources reside | `string` | - | yes |
| `subnet_ids` | Private subnet IDs for worker nodes and cluster ENIs | `list(string)` | - | yes |
| `kubernetes_version` | Target Kubernetes version (e.g. `"1.31"`). `null` uses AWS default | `string` | `null` | no |
| `endpoint_public_access` | Enable public Kubernetes API endpoint | `bool` | `true` | no |
| `endpoint_private_access`| Enable private in-VPC Kubernetes API endpoint | `bool` | `true` | no |
| `public_access_cidrs` | CIDRs permitted to access the public API endpoint | `list(string)` | `["0.0.0.0/0"]` | no |
| `enabled_log_types` | Control plane logs (`api`, `audit`, `authenticator`, etc.) | `list(string)` | `["api", "audit", "authenticator"]` | no |
| `log_retention_days` | Retention in days for CloudWatch logs | `number` | `30` | no |
| `enable_secrets_encryption` | Encrypt k8s secrets with a dedicated AWS KMS key | `bool` | `true` | no |
| `cluster_addons` | Managed add-ons to install | `list(string)` | `["vpc-cni", "kube-proxy", "coredns"]` | no |
| `node_instance_types` | EC2 instance types for the node group | `list(string)` | `["t3.medium"]` | no |
| `node_capacity_type` | Capacity type: `ON_DEMAND` or `SPOT` | `string` | `"ON_DEMAND"` | no |
| `node_disk_size` | Worker node root volume size in GiB | `number` | `20` | no |
| `node_desired_size` | Initial worker node count | `number` | `2` | no |
| `node_min_size` | Minimum worker node count | `number` | `1` | no |
| `node_max_size` | Maximum worker node count | `number` | `4` | no |
| `tags` | Map of tags applied to all resources | `map(string)` | `{}` | no |

#### Outputs

| Name | Description |
|:-----|:------------|
| `cluster_name` | Name of the EKS cluster |
| `cluster_endpoint` | Kubernetes API endpoint |
| `cluster_certificate_authority_data` | Base64-encoded cluster CA certificate |
| `cluster_security_group_id` | Cluster security group ID managed by EKS |
| `oidc_provider_arn` | ARN of the IAM OIDC provider for IRSA trust policies |
| `oidc_issuer_url` | OIDC issuer URL of the cluster |
| `node_role_arn` | IAM role ARN assigned to worker nodes |
| `kubeconfig_command` | Shell command to configure kubectl |

---

## IAM Roles for Service Accounts (IRSA)

The `eks` module configures an OpenID Connect (OIDC) identity provider for the cluster. To grant a Kubernetes service account access to AWS services (e.g. S3, DynamoDB) without giving permissions to entire worker nodes:

```hcl
data "aws_iam_policy_document" "irsa_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:<namespace>:<serviceaccount-name>"]
    }
  }
}

resource "aws_iam_role" "workload_role" {
  name               = "app-workload-role"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume.json
}
```

Annotate your Kubernetes Service Account with the created role ARN:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: <serviceaccount-name>
  namespace: <namespace>
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT_ID>:role/app-workload-role
```

---

## Cost Considerations

Running this project provisions resources that incur AWS charges:

- **EKS Control Plane**: ~$0.10/hour (~$73/month).
- **NAT Gateway**: ~$0.045/hour (~$32.40/month per gateway) plus data processing fees.
- **EC2 Worker Nodes**: Dependent on instance type and count (e.g., `t3.medium` on-demand or spot).
- **AWS KMS Key**: ~$1/month for the custom key plus request volume.
- **CloudWatch Logs**: Based on ingestion volume.

> [!TIP]
> Use `single_nat_gateway = true` during development to avoid incurring costs for multiple NAT Gateways. Always execute `terraform destroy` when you are finished testing.

---

## CI / Automated Validation

Every pull request and push to `main` executes a GitHub Actions workflow matrix that runs:

- Code formatting check: `terraform fmt -check -recursive`
- Provider and module initialization: `terraform init -backend=false`
- Syntax and configuration validation: `terraform validate` across `modules/vpc`, `modules/eks`, and `examples/basic`.

---

## License

This project is licensed under the [MIT License](LICENSE).