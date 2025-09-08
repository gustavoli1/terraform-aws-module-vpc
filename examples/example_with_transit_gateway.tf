locals {
    region = "us-east-1"             // Replace for your Region
    tgw_id = "tgw-12345f836770059" // Replace your Transit Gateway ID
}

provider "aws" {
  region = local.region
}

module "vpc_with_tgw_attachment" {
  source = "../"

  project_name = "vpc-tgw-attach-example"
  environment  = "dev"
  aws_region   = local.region

  vpc_cidr = "10.53.0.0/16"
  azs      = ["${local.region}a", "${local.region}b", "${local.region}c"]

  public_subnets_cidrs = {
    "${local.region}a" = "10.53.1.0/24"
    "${local.region}b" = "10.53.2.0/24"
    "${local.region}c" = "10.53.3.0/24"
  }

  private_subnets_cidrs = {
    "${local.region}a" = "10.53.101.0/24"
    "${local.region}b" = "10.53.102.0/24"
    "${local.region}c" = "10.53.103.0/24"
  }

  enable_nat_gateways = false
  enable_flow_logs    = true

  # Attach to Transit Gateway
  attach_to_transit_gateway = true
  transit_gateway_id        = local.tgw_id 

  # Optional: Specify the subnets for the attachment.
  # If omitted, the private subnets will be used.
  # transit_gateway_attachment_subnet_ids = [
  #   module.vpc_with_tgw_attachment.private_subnet_ids[0],
  #   module.vpc_with_tgw_attachment.private_subnet_ids[1],
  # ]

  private_routes = {
    "single" = [
      {
        cidr_block         = "0.0.0.0/0"
        transit_gateway_id = local.tgw_id 
      }
    ]
  }


  tags = {
    "Example" = "with-transit-gateway"
  }
}
