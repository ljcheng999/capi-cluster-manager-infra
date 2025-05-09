locals {
  ### VPN configuration
  vpc_upstream_name                         = var.vpc_upstream_name
  vpc_upstream_cidr                         = var.vpc_upstream_cidr
  eks_cidr                                  = var.eks_cidr

  upstream_tags = {
    organization                            = "engineering"
    group                                   = "platform"
    team                                    = "enablement"
    stack                                   = "cluster-manager"
    email                                   = "${var.custom_subdomain}.${var.custom_domain}"
    application                             = "cluster-manager-upstream"
    automation_tool                         = "terraform"
  }

  #### EKS cluster manager
  cluster_name                              = var.cluster_name
  cluster_version                           = var.cluster_version
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  public_subnets                            = [for k, v in local.azs : cidrsubnet(local.vpc_upstream_cidr, 8, k)]
  private_subnets                           = [for k, v in local.azs : cidrsubnet(local.vpc_upstream_cidr, 8, k + length(local.azs) + 1)]
  intra_subnets                             = [for k, v in local.azs : cidrsubnet(local.eks_cidr, 1, k)]

  cluster_endpoint_public_access            = var.cluster_endpoint_public_access
  cluster_endpoint_private_access           = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs      = flatten(["${var.my_ip}", var.cluster_endpoint_public_access_cidrs])

  cluster_iam_role_additional_policies = merge(
    var.default_cluster_iam_role_additional_policies,
    var.cluster_iam_role_additional_policies
  )

  self_managed_node_groups = {}

  eks_managed_node_groups = {

    "${local.cluster_name}-${local.system_node_group_name}" = {

      ami_type       = var.ami_type
      ami_id         = var.ami_id
      instance_types = var.default_system_node_instance_types

      enable_bootstrap_user_data = true # instances join cluster from nodegroup
      subnet_ids = module.eks_upstream_vpc.intra_subnets

      update_config = {
        max_unavailable = 1
      }

      min_size = var.system_node_min_size
      max_size = var.system_node_max_size
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = var.system_node_desire_size

      iam_role_name = "${local.cluster_name}-${local.system_node_group_name}"
      iam_role_use_name_prefix = false
      iam_role_additional_policies = merge(
        var.default_iam_role_additional_policies,
        var.node_iam_role_additional_policies
      )

      taints = [
        {
          key    = "node-role.kubernetes.io/control-plane"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ] 

      labels = merge(
        var.default_system_node_labels,
        var.system_node_labels,
        {
          "${var.custom_subdomain}.${var.custom_domain}/${local.system_role_name}-node-role" = "${local.system_role_name}"
        },
      )

      tags = merge(
        {
          "kubernetes.io/cluster/${local.cluster_name}": "owned"
        },
        local.upstream_tags,
      )
    }

    "${local.cluster_name}-${local.user_node_group_name}" = {
      ami_type       = var.ami_type
      ami_id         = var.ami_id
      instance_types = var.default_system_node_instance_types

      enable_bootstrap_user_data = true # instances join cluster from nodegroup
      subnet_ids = module.eks_upstream_vpc.intra_subnets

      update_config = {
        max_unavailable = 1
      }

      min_size = var.user_node_min_size
      max_size = var.user_node_max_size
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = var.user_node_desire_size

      iam_role_name = "${local.cluster_name}-${local.user_node_group_name}"
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
          "kubernetes.io/cluster/${local.cluster_name}": "owned"
        },
        local.upstream_tags,
      )
    }
  }

  enable_cluster_creator_admin_permissions    = var.enable_cluster_creator_admin_permissions
  create_aws_auth_configmap                   = false
  manage_aws_auth_configmap                   = false

  node_security_group_tags = merge(local.upstream_tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = local.cluster_name
  })

  access_entries                              = merge(
    var.additional_access_entries,
    var.cluster_admin_user_arn != "" ? {
      sso_subadmin = {
        principal_arn     = var.cluster_admin_user_arn # Ideally, this should be role arn
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
    } : {},
    var.cluster_admin_role_arn != "" ? {
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
    } : {}
  )

  ### Shared data
  azs                                         = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnet_prefix                       = var.private_subnet_prefix
  local_subnet_prefix                         = var.local_subnet_prefix
  system_role_name                            = var.system_role_name
  user_role_name                              = var.user_role_name

  capi_ingress_elb_policy_name                = var.capi_ingress_elb_policy_name
  capa_nodes_karpenter_controller_policy_name = var.capa_nodes_karpenter_controller_policy_name
  capa_nodes_assume_policy                    = var.capa_nodes_assume_policy

  system_node_group_name                      = var.system_node_group_name
  user_node_group_name                        = var.user_node_group_name
  eks_ingress_alb_policy_name                 = var.capi_ingress_elb_policy_name
  capa_nodes_assume_policy_name               = var.capa_nodes_assume_policy
  capa_nodes_karpender_controller_policy_name = var.capa_nodes_karpenter_controller_policy_name
}