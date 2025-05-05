variable "default_region" {
  description = "AWS default region"
  type        = string
  default     = "us-east-1"
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

################################################################################
# VPC module variables
################################################################################

variable "vpc_tags" {
  description = "Additional tags for the VPC"
  type        = map(string)
  default     = {}
}
variable "private_subnet_prefix" {
  type        = string
  default     = "priv-subnet"
}
variable "local_subnet_prefix" {
  type        = string
  default     = "intra-subnet"
}

################################################################################
# EKS module variables
################################################################################

variable "default_iam_role_additional_policies" {
  type        = map
  default     = {
    "AmazonEBSCSIDriverPolicy": "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
    "AmazonEKSVPCResourceController": "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
    "AmazonSSMManagedInstanceCore": "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  }
}
variable "node_iam_role_additional_policies" {
  type        = map
  default     = {}
}
variable "default_cluster_iam_role_additional_policies" {
  type        = map
  default     = {
    "AmazonSSMManagedInstanceCore": "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}
variable "cluster_iam_role_additional_policies" {
  type        = map
  default     = {}
}

variable "default_system_node_instance_types" {
  type = list
  default = ["m5.large"]
}
variable "default_user_node_instance_types" {
  type = list
  default = ["m5.large"]
}

variable "system_node_min_size" {
  type        = number
  default     = 1
}
variable "system_node_max_size" {
  type        = number
  default     = 3
}
variable "system_node_desire_size" {
  type        = number
  default     = 1
}
variable "user_node_min_size" {
  type        = number
  default     = 1
}
variable "user_node_max_size" {
  type        = number
  default     = 3
}
variable "user_node_desire_size" {
  type        = number
  default     = 1
}

variable "default_system_node_labels" {
  type = map
  default = {
    "node-role.kubernetes.io/control-plane" = "true",
    "karpenter.sh/controller" = "true"
  }
}
variable "default_user_node_labels" {
  type = map
  default = {
    "karpenter.sh/controller" = "true"
  }
}
variable "system_node_labels" {
  type = map
  default = {}
}
variable "user_node_labels" {
  type = map
  default = {}
}

variable "system_node_group_name" {
  type        = string
  default     = "system-node-pool"
}
variable "system_role_name" {
  type        = string
  default     = "system"
}
variable "user_node_group_name" {
  type        = string
  default     = "user-node-pool"
}
variable "user_role_name" {
  type        = string
  default     = "user"
}
variable "capi_ingress_elb_policy_name" {
  type        = string
  default     = "capi-ingress-elb-policy"
}
variable "capa_nodes_karpenter_controller_policy_name" {
  type        = string
  default     = "capa-nodes-karpenter-controller-policy"
}
variable "capa_nodes_assume_policy" {
  type        = string
  default     = "capa-nodes-assume-policy"
}


















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

################################################################################
# EKS Addons
################################################################################
variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the cluster. Addon name can be the map keys or set with `name`"
  type        = any
  default     = {}
}

################################################################################
# aws-auth ConfigMap
################################################################################

variable "create_aws_auth_configmap" {
  description = "Determines whether to create the aws-auth configmap. NOTE - this is only intended for scenarios where the configmap does not exist (i.e. - when using only self-managed node groups). Most users should use `manage_aws_auth_configmap`"
  type        = bool
  default     = false
}

variable "manage_aws_auth_configmap" {
  description = "Determines whether to manage the aws-auth configmap"
  type        = bool
  default     = false
}

variable "aws_auth_roles" {
  description = "List of role maps to add to the aws-auth configmap"
  type        = list(any)
  default     = []
}

variable "aws_auth_users" {
  description = "List of user maps to add to the aws-auth configmap"
  type        = list(any)
  default     = []
}

variable "aws_auth_accounts" {
  description = "List of account maps to add to the aws-auth configmap"
  type        = list(any)
  default     = []
}

################################################################################
# EKS Managed Node Group
################################################################################

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions to create"
  type        = any
  default     = {}
}

variable "eks_managed_node_group_defaults" {
  description = "Map of EKS managed node group default configurations"
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