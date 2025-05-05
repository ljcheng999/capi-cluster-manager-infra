
resource "aws_iam_policy" "amazon_eks_ingress_alb_policy" {
  name        = "${local.cluster_name}-${local.capi_ingress_elb_policy_name}"
  description = "Policy for ${local.cluster_name} CAPI Cluster ELB policy"
  policy      = file("${path.module}/templates/aws/alb-iam-policy.json")

  tags = merge(
    {
      "Name": "${local.cluster_name}-${local.capi_ingress_elb_policy_name}"
    },
    local.upstream_tags,
  )

  depends_on = [
    module.eks_upstream_vpc,
    module.eks_upstream
  ]
}

resource "aws_iam_policy" "capa_nodes_assume_role_policy" {
  name        = "${local.cluster_name}-${local.capa_nodes_assume_policy}"
  description = "Policy for ${local.cluster_name} CAPA node assume policy"
  policy      = file("${path.module}/templates/aws/capa-nodes-assume-role-policy.json")

  tags = merge(
    {
      "Name": "${local.cluster_name}-${local.capa_nodes_assume_policy}"
    },
    local.upstream_tags,
  )

  depends_on = [
    module.eks_upstream_vpc,
    module.eks_upstream
  ]
}

resource "aws_iam_policy" "capa_nodes_karpender_controller_policy" {
  name        = "${local.cluster_name}-${local.capa_nodes_karpenter_controller_policy_name}"
  description = "Policy for ${local.cluster_name} CAPA node karpender controller policy"
  policy      = file("${path.module}/templates/aws/capa-nodes-karpender-controller-policy.json")

  tags = merge(
    {
      "Name": "${local.cluster_name}-${local.capa_nodes_karpenter_controller_policy_name}"
    },
    local.upstream_tags,
  )

  depends_on = [
    module.eks_upstream_vpc,
    module.eks_upstream
  ]
}

resource "aws_iam_role_policy_attachment" "user_pool_policy_attachment" {
  role       = "${local.cluster_name}-${local.user_node_group_name}"
  policy_arn = aws_iam_policy.amazon_eks_ingress_alb_policy.arn
}
resource "aws_iam_role_policy_attachment" "system_pool_policy_attachment" {
  role       = "${local.cluster_name}-${local.system_node_group_name}"
  policy_arn = aws_iam_policy.amazon_eks_ingress_alb_policy.arn
}

resource "aws_iam_role_policy_attachment" "capa_user_pool_policy_attachment" {
  role       = "${local.cluster_name}-${local.user_node_group_name}"
  policy_arn = aws_iam_policy.capa_nodes_assume_role_policy.arn
}
resource "aws_iam_role_policy_attachment" "capa_system_pool_policy_attachment" {
  role       = "${local.cluster_name}-${local.system_node_group_name}"
  policy_arn = aws_iam_policy.capa_nodes_assume_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "capa_user_pool_karpender_controller_policy_attachment" {
  role       = "${local.cluster_name}-${local.user_node_group_name}"
  policy_arn = aws_iam_policy.capa_nodes_karpender_controller_policy.arn
}
resource "aws_iam_role_policy_attachment" "capa_system_pool_karpender_controller_policy_attachment" {
  role       = "${local.cluster_name}-${local.system_node_group_name}"
  policy_arn = aws_iam_policy.capa_nodes_karpender_controller_policy.arn
}