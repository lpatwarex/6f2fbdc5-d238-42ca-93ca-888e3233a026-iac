module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    "Project"     = "6f2fbdc5-d238-42ca-93ca-888e3233a026"
    "Environment" = "dev"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.26.0"

  cluster_name    = "ecommerce-cluster"
  cluster_version = "1.27"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Enable control plane logging
  enable_irsa  = true
  enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  node_groups = {
    eks_nodes = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_type = "t3.medium"

      key_name = "eks-key-pair"
    }
  }

  tags = {
    "Project"     = "6f2fbdc5-d238-42ca-93ca-888e3233a026"
    "Environment" = "dev"
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_eks_cluster" "ecommerce" {
  name     = module.eks.cluster_name
  role_arn = module.eks.cluster_iam_role_arn

  vpc_config {
    subnet_ids = module.vpc.private_subnets
  }

  depends_on = [module.eks]
}

output "cluster_endpoint" {
  description = "EKS Cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS Cluster name"
  value       = module.eks.cluster_name
}
```

This configuration sets up the VPC, the EKS cluster, and a node group. It includes the following:
- A VPC with private and public subnets.
- An EKS cluster configured to log various control plane actions for debugging and compliance.
- A node group with minimal specifications for development environments.
- Outputs that provide the cluster name and endpoint for immediate use after provisioning. 

For production deployments, you should consider enabling additional features such as more sophisticated backup strategies, auto-scaling policies, and more secure key management practices.