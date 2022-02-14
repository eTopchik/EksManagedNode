module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.12.0"


  name = "hw8-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform = "true"
  }
}




module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.6.0"

  cluster_name                    = "HW8cluster"
  cluster_version                 = "1.21"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true


  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }


  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type = "BOTTLEROCKET_x86_64"
    platform = "bottlerocket"
    disk_size              = 10
    instance_types         = ["t3.medium"]
    vpc_security_group_ids = [module.vpc.default_security_group_id]
  }
  eks_managed_node_groups = {

    green = {
      min_size     = 1
      max_size     = 5
      desired_size = 1
      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
    }
  }



  tags = {
    Terraform   = "true"
  }
}

