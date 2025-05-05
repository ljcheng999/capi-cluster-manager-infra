provider "aws" {
  alias = "upstream"
  region = "us-east-1"
  # assume_role {
  #   role_arn = var.assume_role_str
  # }
}

module "eks_upstream" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.36.0"
  providers = {
    aws = aws.upstream
  }

  tags = local.upstream_tags

  cluster_name = local.cluster_name
  cluster_version = local.cluster_version
  cluster_addons = var.cluster_addons

  vpc_id = module.eks_upstream_vpc.vpc_id
  subnet_ids = module.eks_upstream_vpc.intra_subnets

  cluster_endpoint_public_access = local.cluster_endpoint_public_access
  cluster_endpoint_private_access = local.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = local.cluster_endpoint_public_access_cidrs
  control_plane_subnet_ids = module.eks_upstream_vpc.private_subnets


  iam_role_additional_policies          = local.cluster_iam_role_additional_policies
  self_managed_node_groups              = local.self_managed_node_groups
  eks_managed_node_groups               = local.eks_managed_node_groups

  cluster_security_group_additional_rules   = var.cluster_security_group_additional_rules
  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = local.enable_cluster_creator_admin_permissions
  access_entries = local.access_entries
}

module "eks_upstream_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  providers = {
    aws = aws.upstream
  }

  name = local.vpc_upstream_name
  cidr = local.vpc_upstream_cidr
  secondary_cidr_blocks = [local.eks_cidr] # can add up to 5 total CIDR blocks

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_upstream_cidr, 8, k)]

  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_upstream_cidr, 8, k + length(local.azs) + 1)]
  intra_subnets    = [for k, v in local.azs : cidrsubnet(local.eks_cidr, 1, k)]

  # public_subnet_names omitted to show default name generation for all subnets
  private_subnet_names     = ["${local.vpc_upstream_name}-${local.private_subnet_prefix}-1a", "${local.vpc_upstream_name}-${local.private_subnet_prefix}-1b"]
  intra_subnet_names       = ["${local.vpc_upstream_name}-${local.local_subnet_prefix}-1a", "${local.vpc_upstream_name}-${local.local_subnet_prefix}-1b"]

  create_database_subnet_group  = false
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = false


  enable_ipv6                                   = true
  public_subnet_assign_ipv6_address_on_creation = false
  private_subnet_enable_resource_name_dns_aaaa_record_on_launch = false
  intra_subnet_enable_dns64 = false
  intra_subnet_enable_resource_name_dns_aaaa_record_on_launch = false
  create_multiple_intra_route_tables = true

  public_subnet_ipv6_prefixes   = [0, 1]
  private_subnet_ipv6_prefixes  = [3, 4]

  public_subnet_tags = merge(
    {
      "kubernetes.io/role/elb": 1,
      "kubernetes.io/cluster/${local.cluster_name}": "shared"
    },
    local.upstream_tags,
  )

  private_subnet_tags = merge(
    {
      "kubernetes.io/role/elb": 1,
      "kubernetes.io/cluster/${local.cluster_name}": "shared"
    },
    local.upstream_tags,
  )
  tags = local.upstream_tags
}


output "resources_east_vpc" {
  value = module.eks_upstream_vpc
}
