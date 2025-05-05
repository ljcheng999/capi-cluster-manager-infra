

resource "aws_nat_gateway" "local_nat_gws" {
  for_each = { for k, private_subnet_object in module.eks_upstream_vpc.private_subnet_objects[*] : k => private_subnet_object }

  connectivity_type = "private"
  subnet_id         = each.value.id

  depends_on    = [
    module.eks_upstream_vpc,
  ]

  tags = merge(
    {
      "Name": "intra-nat-gw-${index(module.eks_upstream_vpc.private_subnet_objects, each.value) + 1}"
    },
    local.upstream_tags
  )
}

resource "aws_route" "intra_route_nat_gws" {
  count = "${length(module.eks_upstream_vpc.intra_subnets)}"

  route_table_id            = module.eks_upstream_vpc.intra_route_table_ids[count.index]
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.local_nat_gws[count.index].id
  # vpc_peering_connection_id = "pcx-45ff3dc1"
}

resource "aws_route_table_association" "intra_subnet_route_table_associations" {
  count = "${length(module.eks_upstream_vpc.intra_subnets)}"

  subnet_id      = module.eks_upstream_vpc.intra_subnets[count.index]
  route_table_id = module.eks_upstream_vpc.intra_route_table_ids[count.index]
}
