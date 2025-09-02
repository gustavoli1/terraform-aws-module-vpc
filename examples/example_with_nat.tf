provider "aws" {
  region = "us-east-2"
}

module "vpc" {
  source = "../"

  project_name = "vpc-egress-with-nat"
  environment  = "live"
  aws_region   = "us-east-2"
  
  enable_nat_gateways = true

  vpc_cidr = "10.1.0.0/16" 
  azs      = ["us-east-2a", "us-east-2b", "us-east-2c"]

  public_subnets_cidrs = {
    "us-east-2a" = "10.1.1.0/24"
    "us-east-2b" = "10.1.2.0/24"
    "us-east-2c" = "10.1.3.0/24"
  }

  private_subnets_cidrs = {
    "us-east-2a" = "10.1.101.0/24"
    "us-east-2b" = "10.1.102.0/24"
    "us-east-2c" = "10.1.103.0/24"
  }

  enable_flow_logs = true

  private_routes = {
    "us-east-2a" = [
      {
        cidr_block         = "172.16.0.0/16"
        transit_gateway_id = "tgw-1234567890abcdef0" // Replace your Transit Gateway ID
      }
    ],
    "us-east-2b" = [
      {
        cidr_block         = "172.16.0.0/16"
        transit_gateway_id = "tgw-1234567890abcdef0" // Replace your Transit Gateway ID
      }
    ],
    "us-east-2c" = [
      {
        cidr_block         = "172.16.0.0/16"
        transit_gateway_id = "tgw-1234567890abcdef0" // Replace your Transit Gateway ID
      }
    ]
  }

  tags = {
    "Owner" = "my-team"
  }
}