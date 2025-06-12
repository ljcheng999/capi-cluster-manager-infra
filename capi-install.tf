resource "null_resource" "name" {
  provisioner "local-exec" {
    command = templatefile("${path.module}/templates/capi/initilization.sh", {
      cluster_name           = var.cluster_name,
      clusterctl_version     = var.clusterctl_version,
      clusterawsadm_version  = var.clusterawsadm_version,
      region                 = local.region,
      cloud_provider         = var.cloud_provider == "" ? var.default_cloud_provider : var.cloud_provider,
      linux_arch_amd64       = "amd64",
      linux_arch_arm64       = "arm64",
      cluster_federate_arn   = module.eks_upstream.oidc_provider_arn,
      cluster_oidc_provider  = module.eks_upstream.oidc_provider,
      aws_managed_account_id = var.aws_managed_account_id == "" ? var.default_aws_capi_managed_account : var.aws_managed_account_id,
      # assume_role_arn       = var.cluster_admin_role_arn, # for CAPI, the user for the management cluster needs to have admin access
      # assume_role_arn = var.cluster_admin_user_arn,
    })
    interpreter = ["bash", "-c"]
  }

  triggers = {
    always_run            = "${timestamp()}" # Only for testing
    clusterctl_version    = var.clusterctl_version,
    clusterawsadm_version = var.clusterawsadm_version
  }

  depends_on = [
    module.eks_upstream
  ]
}
