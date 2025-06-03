resource "null_resource" "name" {
  provisioner "local-exec" {
    command = templatefile("${path.module}/templates/capi/initilization.sh", {
      cluster_name          = var.cluster_name,
      clusterctl_version    = var.clusterctl_version,
      clusterawsadm_version = var.clusterawsadm_version,
      region                = local.region,
      cloud_provider        = var.cloud_provider == "" ? var.default_cloud_provider : var.cloud_provider
    })
    interpreter = ["bash", "-c"]
  }

  triggers = {
    clusterctl_version    = var.clusterctl_version,
    clusterawsadm_version = var.clusterawsadm_version
  }

  depends_on = [
    module.eks_upstream
  ]
}
