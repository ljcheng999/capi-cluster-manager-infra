
resource "aws_iam_role" "capa_cluster_service_account_role" {
  name = "${var.cluster_name}-cluster-service-account"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRoleWithWebIdentity",
        Effect = "Allow",
        Principal = {
          Federated = module.bfe_cm.oidc_provider_arn
        },
        Condition = {
          "StringLike" : {
            "${module.eks_upstream.oidc_provider}:aud" : "sts.amazonaws.com",
            "${module.eks_upstream.oidc_provider}:sub" : "system:serviceaccount:argocd:*"
          }
        }
      }
    ]
  })

  tags = merge(
    {
      "Name" : "${var.cluster_name}-cluster-service-account"
    },
    var.tags,
  )
}

resource "aws_iam_policy" "capa_cluster_service_account_policy" {
  name        = "${var.cluster_name}-cluster-service-account-policy"
  description = "Policy for ${var.cluster_name} CAPI Cluster SA policy"
  policy      = file("${path.module}/templates/aws/capa-cluster-service-account.json")

  tags = merge(
    {
      "Name" : "${var.cluster_name}-cluster-service-account"
    },
    var.tags,
  )
}


resource "aws_iam_role_policy_attachment" "capa_cluster_service_account_policy_attachment" {
  role       = aws_iam_role.capa_cluster_service_account_role.name
  policy_arn = aws_iam_policy.capa_cluster_service_account_policy.arn
}
