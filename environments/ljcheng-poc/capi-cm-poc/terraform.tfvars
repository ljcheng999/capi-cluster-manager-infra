

cluster_name    = "capi-cm-poc"
cluster_version = "1.33"
region          = ""
cloud_provider  = "aws"

aws_managed_account_id = "1234567" # REPLACE THIS TO YOUR DOWNSTREAM AWS ACCOUNT

### You need to find an AMI that has kubelet installed, the default AWS AMI does not
### Reference: https://stackoverflow.com/questions/64515585/aws-eks-nodegroup-create-failed-instances-failed-to-join-the-kubernetes-clust
ami_id   = "ami-0e92438dc9afbbde5" #ubuntu-eks/k8s_1.32/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20250430
ami_type = "AL2_x86_64"

node_security_group_additional_rules = {
  ingress_self_all = {
    description = "Node to itself"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    type        = "ingress"
    self        = true
  }
}

custom_domain    = "kubesources.com"
custom_subdomain = "ljcheng-capi"

clusterctl_version    = "v1.10.2" #refer to https://github.com/kubernetes-sigs/cluster-api/releases
clusterawsadm_version = "v2.8.3"  #refer to https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases

cluster_addons = {
  coredns                = {}
  eks-pod-identity-agent = {}
  kube-proxy             = {}
  vpc-cni                = {}
  aws-ebs-csi-driver     = {}
}

enable_cluster_creator_admin_permissions = false
cluster_endpoint_public_access           = true
cluster_endpoint_public_access_cidrs = [
  # traffic from its Web/API fleet
  "34.74.90.64/28",
  "34.74.226.0/24",
  # Gitlab runner IPs
  "34.23.0.0/16",
  "34.24.0.0/15",
  "34.26.0.0/16",
  "34.73.0.0/16",
  "34.74.0.0/15",
  "34.98.128.0/21",
  "34.112.0.0/16",
  "34.118.250.0/23",
  "34.138.0.0/15",
  "34.148.0.0/16",
  "34.152.72.0/21",
  "34.177.40.0/21",
  "34.183.4.0/23",
  "34.184.4.0/23",
  "35.185.0.0/17",
  "35.190.128.0/18",
  "35.196.0.0/16",
  "35.207.0.0/18",
  "35.211.0.0/16",
  "35.220.0.0/20",
  "35.227.0.0/17",
  "35.229.16.0/20",
  "35.229.32.0/19",
  "35.229.64.0/18",
  "35.231.0.0/16",
  "35.237.0.0/16",
  "35.242.0.0/20",
  "35.243.128.0/17",
  "104.196.0.0/18",
  "104.196.65.0/24",
  "104.196.66.0/23",
  "104.196.68.0/22",
  "104.196.96.0/19",
  "104.196.128.0/18",
  "104.196.192.0/19",
  "162.216.148.0/22",
]


