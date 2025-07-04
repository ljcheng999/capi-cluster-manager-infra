variable "default_region" {
  description = "AWS default region"
  type        = string
  default     = "us-east-1"
}
variable "default_cloud_provider" {
  type    = string
  default = "aws"
}
variable "cloud_provider" {
  type    = string
  default = ""
}
variable "region" {
  description = "AWS default region"
  type        = string
  default     = ""
}

# variable "tags" {
#   description = "Required tags - used for billing metadata and cloud-related monitoring, automation"

#   type = object({
#     organization    = string
#     group           = string
#     team            = string
#     stack           = string
#     email           = string
#     application     = string
#     automation_tool = string
#     automation_path = string
#   })

#   validation {
#     condition     = (var.tags.organization != null) || (var.tags.group != null) || (var.tags.team != null) || (var.tags.stack != null) || (var.tags.email != null) || (var.tags.application != null) || (var.tags.automation_tool != null) || (var.tags.automation_path != null)
#     error_message = "All `var.tags` must be defined: \"group\", \"team\", \"stack\", \"email\", \"application\", \"automation_tool\", \"automation_path\""
#   }
# }

variable "aws_managed_account_id" {
  type    = string
  default = ""
}
variable "default_aws_capi_managed_account" {
  type    = string
  default = "012345678912"
}

################################################################################
# VPC module variables
################################################################################

variable "vpc_tags" {
  description = "Additional tags for the VPC"
  type        = map(string)
  default     = {}
}
variable "private_subnet_prefix" {
  type    = string
  default = "private-us-east"
}
variable "local_subnet_prefix" {
  type    = string
  default = "intra-us-east"
}
variable "eks_cidr" {
  type    = string
  default = "100.64.0.0/16"
}
variable "vpc_upstream_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "vpc_upstream_name" {
  type    = string
  default = "upstream_vpc"
}

################################################################################
# EKS module variables
################################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}

variable "cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.27`)"
  type        = string
  default     = null
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = []
}

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "default_iam_role_additional_policies" {
  type = map(any)
  default = {
    "AmazonEBSCSIDriverPolicy" : "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
    "AmazonEKSVPCResourceController" : "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
    "AmazonSSMManagedInstanceCore" : "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  }
}
variable "my_ip" {
  type    = string
  default = ""
}

variable "custom_domain" {
  type    = string
  default = "kubesources.com"
}
variable "custom_subdomain" {
  type    = string
  default = "ljcheng"
}

variable "node_iam_role_additional_policies" {
  type    = map(any)
  default = {}
}
variable "default_cluster_iam_role_additional_policies" {
  type = map(any)
  default = {
    "AmazonSSMManagedInstanceCore" : "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}
variable "cluster_iam_role_additional_policies" {
  type    = map(any)
  default = {}
}

variable "default_system_node_instance_types" {
  type    = list(any)
  default = ["m5.large"]
}
variable "default_user_node_instance_types" {
  type    = list(any)
  default = ["m5.large"]
}

variable "system_node_min_size" {
  type    = number
  default = 1
}
variable "system_node_max_size" {
  type    = number
  default = 2
}
variable "system_node_desire_size" {
  type    = number
  default = 1
}
variable "user_node_min_size" {
  type    = number
  default = 1
}
variable "user_node_max_size" {
  type    = number
  default = 2
}
variable "user_node_desire_size" {
  type    = number
  default = 1
}

variable "default_system_node_labels" {
  type = map(any)
  default = {
    "node-role.kubernetes.io/control-plane" = "true",
    "karpenter.sh/controller"               = "true"
  }
}
variable "default_user_node_labels" {
  type = map(any)
  default = {
    "karpenter.sh/controller" = "true"
  }
}
variable "system_node_labels" {
  type    = map(any)
  default = {}
}
variable "user_node_labels" {
  type    = map(any)
  default = {}
}

variable "system_node_group_name" {
  type    = string
  default = "system-node-pool"
}
variable "system_role_name" {
  type    = string
  default = "system"
}
variable "user_node_group_name" {
  type    = string
  default = "user-node-pool"
}
variable "user_role_name" {
  type    = string
  default = "user"
}
variable "capi_ingress_elb_policy_name" {
  type    = string
  default = "capi-ingress-elb-policy"
}
variable "capa_nodes_karpenter_controller_policy_name" {
  type    = string
  default = "capa-nodes-karpenter-controller-policy"
}
variable "capa_nodes_assume_policy" {
  type    = string
  default = "capa-nodes-assume-policy"
}

variable "ami_id" {
  type    = string
  default = ""
}
variable "ami_type" {
  type    = string
  default = "AL2_x86_64"
}

################################################################################
# Access Entry
################################################################################

variable "cluster_admin_user_arn" {
  description = "ARN of admin user/role to add to the cluster"
  type        = string
  default     = ""
}
variable "cluster_admin_role_arn" {
  description = "Admin role Map of access entries to add to the cluster"
  type        = string
  default     = ""
}
variable "aws_eks_cluster_admin_policy" {
  description = "ARN of admin user/role policy to add to the cluster"
  type        = string
  default     = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
}
variable "default_access_entries" {
  description = "Map of access entries to add to the cluster"
  type        = any
  default     = {}
}
variable "enable_cluster_creator_admin_permissions" {
  description = "Indicates whether or not to add the cluster creator (the identity used by Terraform) as an administrator via access entry"
  type        = bool
  default     = false
}


################################################################################
# EKS Addons
################################################################################
variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the cluster. Addon name can be the map keys or set with `name`"
  type        = any
  default = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }
}

################################################################################
# Cluster Node group Security Group
################################################################################
variable "node_security_group_additional_rules" {
  description = "List of additional security group rules to add to the node security group created. Set `source_cluster_security_group = true` inside rules to set the `cluster_security_group` as source"
  type        = any
  default     = {}
}


################################################################################
# Cluster Security Group
################################################################################

variable "cluster_security_group_additional_rules" {
  description = "List of additional security group rules to add to the cluster security group created. Set `source_node_security_group = true` inside rules to set the `node_security_group` as source"
  type        = any
  default     = {}
}

################################################################################
# CAPI configuration
################################################################################
variable "clusterctl_version" {
  type    = string
  default = "v2.8.3"
}
variable "clusterawsadm_version" {
  type    = string
  default = "v2.8.3"
}
