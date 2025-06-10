locals {
  region = var.region == "" ? var.default_region : var.region
  ### VPN configuration
  vpc_upstream_name = var.vpc_upstream_name
  vpc_upstream_cidr = var.vpc_upstream_cidr
  eks_cidr          = var.eks_cidr

  upstream_tags = {
    organization    = "engineering"
    group           = "platform"
    team            = "enablement"
    stack           = "cluster-manager"
    email           = "${var.custom_subdomain}.${var.custom_domain}"
    application     = "cluster-manager-upstream"
    automation_tool = "terraform"
  }


  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_upstream_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_upstream_cidr, 8, k + length(local.azs) + 1)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(local.eks_cidr, 1, k)]


  cluster_iam_role_additional_policies = merge(
    var.default_cluster_iam_role_additional_policies,
    var.cluster_iam_role_additional_policies
  )

  self_managed_node_groups = {}

  eks_managed_node_groups = {

    "${var.cluster_name}-${var.system_node_group_name}" = {

      ami_type       = var.ami_type
      ami_id         = var.ami_id
      instance_types = var.default_system_node_instance_types

      enable_bootstrap_user_data = true # instances join cluster from nodegroup
      subnet_ids                 = module.eks_upstream_vpc.intra_subnets

      update_config = {
        max_unavailable = 1
      }

      min_size = var.system_node_min_size
      max_size = var.system_node_max_size
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = var.system_node_desire_size

      iam_role_name            = "${var.cluster_name}-${var.system_node_group_name}"
      iam_role_use_name_prefix = false
      iam_role_additional_policies = merge(
        var.default_iam_role_additional_policies,
        var.node_iam_role_additional_policies
      )

      taints = [
        {
          key    = "node.${var.custom_domain}/role"
          value  = "${var.system_role_name}"
          effect = "NO_SCHEDULE"
        }
      ]

      labels = merge(
        var.default_system_node_labels,
        var.system_node_labels,
        {
          "${var.cluster_name}.${var.custom_domain}/node-role" = "${var.system_role_name}"
        },
      )

      tags = merge(
        {
          "kubernetes.io/cluster/${var.cluster_name}" : "owned"
        },
        local.upstream_tags,
      )
    }

    "${var.cluster_name}-${var.user_node_group_name}" = {
      ami_type       = var.ami_type
      ami_id         = var.ami_id
      instance_types = var.default_system_node_instance_types

      enable_bootstrap_user_data = true # instances join cluster from nodegroup
      subnet_ids                 = module.eks_upstream_vpc.intra_subnets

      update_config = {
        max_unavailable = 1
      }

      min_size = var.user_node_min_size
      max_size = var.user_node_max_size
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = var.user_node_desire_size

      iam_role_name            = "${var.cluster_name}-${var.user_node_group_name}"
      iam_role_use_name_prefix = false
      iam_role_additional_policies = merge(
        var.default_iam_role_additional_policies,
        var.node_iam_role_additional_policies
      )

      labels = merge(
        var.default_user_node_labels,
        var.user_node_labels
      )

      tags = merge(
        {
          "kubernetes.io/cluster/${var.cluster_name}" : "owned"
        },
        local.upstream_tags,
      )
    }
  }

  create_aws_auth_configmap = false
  manage_aws_auth_configmap = false

  node_security_group_tags = merge(local.upstream_tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = var.cluster_name
  })

  ### Because the runner role can be assume, so we can use this for a new access entry for eks
  # enable_cluster_creator_admin_permissions = var.cluster_admin_role_arn != "" ? true : false
  enable_cluster_creator_admin_permissions = var.cluster_admin_user_arn != "" ? true : false
  access_entries = var.cluster_admin_role_arn != "" ? {
    sso_subadmin = {
      principal_arn     = var.cluster_admin_role_arn # Ideally, this should be role arn
      user_name         = "sso-admin"
      kubernetes_groups = ["sso-admin-group"]

      policy_associations = {
        sso_subadmin_policy = {
          policy_arn = var.aws_eks_cluster_admin_policy
          access_scope = {
            namespaces = []
            type       = "cluster"
          }
        }
      }
    }
    # subadmin_user = {
    #   principal_arn     = var.cluster_admin_user_arn # Local test only
    #   user_name         = "sso-admin"
    #   kubernetes_groups = ["sso-admin-group"]

    #   policy_associations = {
    #     sso_subadmin_policy = {
    #       policy_arn = var.aws_eks_cluster_admin_policy
    #       access_scope = {
    #         namespaces = []
    #         type       = "cluster"
    #       }
    #     }
    #   }
    # }
  } : var.default_access_entries

  ### Shared data
  azs                   = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnet_prefix = var.private_subnet_prefix
  local_subnet_prefix   = var.local_subnet_prefix
}
