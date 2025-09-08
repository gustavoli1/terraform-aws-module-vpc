locals {
    region = "us-east-1"             // Replace for your Region
    tgw_id = "tgw-0ff5efbf836770059" // Replace your Transit Gateway ID
}

provider "aws" {
  region = local.region
}


module "vpc" {
  source = "../"

  project_name = "vpc-egress-with-nat"
  environment  = "live"
  aws_region   = local.region
  
  enable_nat_gateways = true

  vpc_cidr = "10.1.0.0/16" 
  azs      = ["${local.region}a", "${local.region}b", "${local.region}c"]

  public_subnets_cidrs = {
    "${local.region}a" = "10.1.1.0/24"
    "${local.region}b" = "10.1.2.0/24"
    "${local.region}c" = "10.1.3.0/24"
  }

  private_subnets_cidrs = {
    "${local.region}a" = "10.1.101.0/24"
    "${local.region}b" = "10.1.102.0/24"
    "${local.region}c" = "10.1.103.0/24"
  }

  enable_flow_logs = true

  attach_to_transit_gateway = true

  transit_gateway_id        = local.tgw_id

  private_routes = {
    "${local.region}a" = [
      {
        cidr_block         = "172.16.0.0/16"
        transit_gateway_id = local.tgw_id // Replace your Transit Gateway ID
      }
    ],
    "${local.region}b" = [
      {
        cidr_block         = "172.16.0.0/16"
        transit_gateway_id = local.tgw_id // Replace your Transit Gateway ID
      }
    ],
    "${local.region}c" = [
      {
        cidr_block         = "172.16.0.0/16"
        transit_gateway_id = local.tgw_id // Replace your Transit Gateway ID
      }
    ]
  }

  tags = {
    "Owner" = "my-team"
  }
}
