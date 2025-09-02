locals {
  common_tags = merge(
    {
      "Project"     = var.project_name
      "Environment" = var.environment
    },
    var.tags
  )

  transit_gateway_attachment_subnet_ids = length(var.transit_gateway_attachment_subnet_ids) > 0 ? var.transit_gateway_attachment_subnet_ids : [for k, s in aws_subnet.private : s.id]
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.project_name}-vpc"
    }
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.project_name}-igw"
    }
  )
}

resource "aws_subnet" "public" {
  for_each = var.public_subnets_cidrs

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.project_name}-public-subnet-${each.key}"
    }
  )
}

resource "aws_subnet" "private" {
  for_each = var.private_subnets_cidrs

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.project_name}-private-subnet-${each.key}"
    }
  )
}

resource "aws_eip" "nat" {
  for_each = var.enable_nat_gateways ? toset(keys(var.private_subnets_cidrs)) : toset([])

  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.project_name}-nat-eip-${each.key}"
    }
  )
}

resource "aws_nat_gateway" "nat" {
  for_each = var.enable_nat_gateways ? toset(keys(var.private_subnets_cidrs)) : toset([])

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.project_name}-nat-gateway-${each.key}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  dynamic "route" {
    for_each = var.public_routes
    content {
      cidr_block                = route.value.cidr_block
      gateway_id                = try(route.value.gateway_id, null)
      nat_gateway_id            = try(route.value.nat_gateway_id, null)
      network_interface_id      = try(route.value.network_interface_id, null)
      vpc_peering_connection_id = try(route.value.vpc_peering_connection_id, null)
      transit_gateway_id        = try(route.value.transit_gateway_id, null)
    }
  }

  tags = merge(
    local.common_tags,
    {
      "Name" = "rtb-public"
    }
  )
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = var.enable_nat_gateways ? toset(keys(var.private_subnets_cidrs)) : toset(["single"])

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateways ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat[each.key].id
    }
  }

  dynamic "route" {
    for_each = lookup(var.private_routes, each.key, [])
    content {
      cidr_block                = route.value.cidr_block
      gateway_id                = try(route.value.gateway_id, null)
      nat_gateway_id            = try(route.value.nat_gateway_id, null)
      network_interface_id      = try(route.value.network_interface_id, null)
      vpc_peering_connection_id = try(route.value.vpc_peering_connection_id, null)
      transit_gateway_id        = try(route.value.transit_gateway_id, null)
    }
  }

  tags = merge(
    local.common_tags,
    {
      "Name" = var.enable_nat_gateways ? "${var.project_name}-private-rt-${each.key}" : "rtb-private-spoke"
    }
  )
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = var.enable_nat_gateways ? aws_route_table.private[each.key].id : aws_route_table.private["single"].id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat([for k, v in aws_route_table.private : v.id], [aws_route_table.public.id])


  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.project_name}-s3-vpc-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat([for k, v in aws_route_table.private : v.id], [aws_route_table.public.id])

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.project_name}-dynamodb-vpc-endpoint"
    }
  )
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name_prefix       = "/aws/vpc-flow-logs/${var.project_name}"
  retention_in_days = var.flow_log_retention_in_days

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.project_name}-flow-logs-group"
    }
  )
}

resource "aws_flow_log" "main" {
  count = var.enable_flow_logs ? 1 : 0

  iam_role_arn    = aws_iam_role.flow_logs_role.arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.project_name}-flow-log"
    }
  )
}

resource "aws_iam_role" "flow_logs_role" {
  name_prefix = "${var.project_name}-flow-logs-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "flow_logs_policy" {
  name_prefix = "${var.project_name}-flow-logs-policy"
  role        = aws_iam_role.flow_logs_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  count = var.attach_to_transit_gateway ? 1 : 0

  subnet_ids         = local.transit_gateway_attachment_subnet_ids
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.project_name}-tgw-attachment"
    }
  )
}

