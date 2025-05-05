locals {
  ### VPN configuration
  vpc_upstream_name                         = "upstream_vpc"
  vpc_upstream_cidr                         = "10.0.0.0/16"
  eks_cidr                                  = "100.64.0.0/16"

  upstream_tags = {
    organization                            = "engineering"
    group                                   = "platform"
    team                                    = "enablement"
    stack                                   = "cluster-manager"
    email                                   = "test123@gmail.com"
    application                             = "cluster-manager-upstream"
    automation_tool                         = "terraform"
  }

  #### EKS cluster manager
  cluster_name                              = "cluster-manager"
  cluster_version                           = "1.31"
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  cluster_endpoint_public_access            = true
  cluster_endpoint_private_access           = true
  cluster_endpoint_public_access_cidrs = [
    "73.14.227.55/32",
    # "142.136.0.0/16",
    # "107.22.62.130/32", #specflow-qa
    # "3.213.73.41/32", #specflow-qa
    # "3.224.130.80/32", #specflow-qa
    # "3.218.88.57/32", #specflow-qa
  ]

  cluster_iam_role_additional_policies = merge(
    var.default_cluster_iam_role_additional_policies,
    var.cluster_iam_role_additional_policies
  )

  self_managed_node_groups = {}

  eks_managed_node_groups = {

    "${local.cluster_name}_${local.system_node_group_name}" = {

      ami_type       = "AL2_x86_64"
      instance_types = var.default_system_node_instance_types
      ### You need to find an AMI that has kubelet installed, the default AWS AMI does not
      ### Reference: https://stackoverflow.com/questions/64515585/aws-eks-nodegroup-create-failed-instances-failed-to-join-the-kubernetes-clust
      ami_id         = "ami-0e92438dc9afbbde5"

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

      labels = merge(
        var.default_system_node_labels,
        var.system_node_labels,
        {
          "ljcheng.toolbox.com/${local.system_role_name}-node-role" = "${local.system_role_name}"
        },
      )

      tags = merge(
        {
          "kubernetes.io/cluster/${local.cluster_name}": "owned"
        },
        local.upstream_tags,
      )
    }

    "${local.cluster_name}_${local.user_node_group_name}" = {
      ami_type       = "AL2_x86_64"
      instance_types = var.default_user_node_instance_types
      ### You need to find an AMI that has kubelet installed, the default AWS AMI does not
      ### Reference: https://stackoverflow.com/questions/64515585/aws-eks-nodegroup-create-failed-instances-failed-to-join-the-kubernetes-clust
      ami_id         = "ami-0e92438dc9afbbde5"

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

  enable_cluster_creator_admin_permissions    = true
  create_aws_auth_configmap                   = false
  manage_aws_auth_configmap                   = false

  node_security_group_tags = merge(local.upstream_tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = local.cluster_name
  })

  access_entries = {}

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