

cluster_name                              = "capi-cm-poc"
cluster_version                           = "1.31"

enable_cluster_creator_admin_permissions  = false
cluster_endpoint_public_access = true
cluster_endpoint_public_access_cidrs = []

### You need to find an AMI that has kubelet installed, the default AWS AMI does not
### Reference: https://stackoverflow.com/questions/64515585/aws-eks-nodegroup-create-failed-instances-failed-to-join-the-kubernetes-clust
ami_id         = "ami-0e92438dc9afbbde5"
ami_type       = "AL2_x86_64"

custom_domain  = "kubesources.com"
custom_subdomain = "ljcheng"