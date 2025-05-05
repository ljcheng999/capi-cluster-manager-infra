locals {
  ### VPN configuration
  vpc_upstream_name = "upstream_vpc"
  vpc_upstream_cidr = "10.0.0.0/16"
  eks_cidr          = "100.64.0.0/16"

  upstream_tags = {
    organization    = "engineering"
    group           = "platform"
    team            = "enablement"
    stack           = "cluster-manager"
    email           = "test123@gmail.com"
    application     = "cluster-manager-upstream"
    automation_tool = "terraform"
  }


  #### EKS cluster manager
  cluster_name = "cluster-manager"
  cluster_name_underscore = "cluster_manager"
  cluster_version = "1.31"
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access_cidrs = [
    "73.14.227.55/32",
    # "142.136.0.0/16",
    # "107.22.62.130/32", #specflow-qa
    # "3.213.73.41/32", #specflow-qa
    # "3.224.130.80/32", #specflow-qa
    # "3.218.88.57/32", #specflow-qa
  ]

  cluster_iam_role_additional_policies = {
    "AmazonSSMManagedInstanceCore": "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  self_managed_node_groups = {}
  eks_managed_node_groups = {
    "${local.cluster_name_underscore}_${local.system_role_name}_node_pool" = {

      ami_type       = "AL2_x86_64"
      instance_types = ["m5.large"]
      ### You need to find an AMI that has kubelet installed, the default AWS AMI does not
      ### Reference: https://stackoverflow.com/questions/64515585/aws-eks-nodegroup-create-failed-instances-failed-to-join-the-kubernetes-clust
      ami_id         = "ami-0e92438dc9afbbde5"

      enable_bootstrap_user_data = true # instances join cluster from nodegroup
      subnet_ids = module.eks_upstream_vpc.intra_subnets

      update_config = {
        max_unavailable = 1
      }

      min_size = 1
      max_size = 3
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 1

      iam_role_name = "${local.cluster_name}-${local.system_role_name}-node-pool"
      iam_role_use_name_prefix = false
      iam_role_additional_policies = {
        "AmazonSSMManagedInstanceCore": "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "AmazonEBSCSIDriverPolicy": "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
        "AmazonEKSVPCResourceController": "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
      }

      labels = {
        "node-role.kubernetes.io/control-plane" = "true"
        "ljcheng.toolbox.com/${local.system_role_name}-node-role" = "${local.system_role_name}"
        "karpenter.sh/controller" = "true"
      }

      tags = merge(
        {
          "kubernetes.io/cluster/${local.cluster_name}": "owned"
        },
        local.upstream_tags,
      )
    }
    "${local.cluster_name_underscore}_${local.user_role_name}_node_pool" = {

      ami_type       = "AL2_x86_64"
      instance_types = ["m5.large"]
      ### You need to find an AMI that has kubelet installed, the default AWS AMI does not
      ### Reference: https://stackoverflow.com/questions/64515585/aws-eks-nodegroup-create-failed-instances-failed-to-join-the-kubernetes-clust
      ami_id         = "ami-0e92438dc9afbbde5"

      enable_bootstrap_user_data = true # instances join cluster from nodegroup
      subnet_ids = module.eks_upstream_vpc.intra_subnets

      update_config = {
        max_unavailable = 1
      }

      min_size = 1
      max_size = 3
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 1

      iam_role_name = "${local.cluster_name}-${local.user_role_name}-node-pool"
      iam_role_use_name_prefix = false
      iam_role_additional_policies = {
        "AmazonSSMManagedInstanceCore": "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "AmazonEBSCSIDriverPolicy": "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
        "AmazonEKSVPCResourceController": "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
      }

      labels = {
        "karpenter.sh/controller" = "true"
      }

      tags = merge(
        {
          "kubernetes.io/cluster/${local.cluster_name}": "owned"
        },
        local.upstream_tags,
      )
    }
  }

  enable_cluster_creator_admin_permissions = true
  create_aws_auth_configmap = false
  manage_aws_auth_configmap = false

  node_security_group_tags = merge(local.upstream_tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = local.cluster_name
  })

  access_entries = {}
  # access_entries = {
  #   # One access entry with a policy associated
  #   sso_subadmin = {
  #     principal_arn     = "arn:aws:iam::533267295140:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_subaccount_admins_b3ac2bb7df34e2e5"
  #     user_name         = "sso-admin"
  #     kubernetes_groups = ["sso-admin-group"]

  #     policy_associations = {
  #       sso_subadmin_policy = {
  #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  #         access_scope = {
  #           namespaces = []
  #           type       = "cluster"
  #         }
  #       }
  #     }
  #   }
  # }

  ### Shared data
  azs                   = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnet_prefix = "priv-subnet"
  local_subnet_prefix   = "intra-subnet"
  system_role_name      = "system"
  user_role_name      = "user"
}