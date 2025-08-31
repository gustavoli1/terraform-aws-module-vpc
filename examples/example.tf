provider "aws" {
  region = "us-east-2"
}

module "vpc" {
  source = "../"

  project_name = "vpc-egress"
  environment  = "live"
  aws_region   = "us-east-2"
  
  enable_nat_gateways = false 

  vpc_cidr = "10.0.0.0/16"
  azs      = ["us-east-2a", "us-east-2b", "us-east-2c"]

  public_subnets_cidrs = {
    "us-east-2a" = "10.0.1.0/24"
    "us-east-2b" = "10.0.2.0/24"
    "us-east-2c" = "10.0.3.0/24"
  }

  private_subnets_cidrs = {
    "us-east-2a" = "10.0.101.0/24"
    "us-east-2b" = "10.0.102.0/24"
    "us-east-2c" = "10.0.103.0/24"
  }

  enable_flow_logs = true

  private_routes = {
    "single" = [
      {
        cidr_block         = "0.0.0.0/0"
        transit_gateway_id = "tgw-1234567890abcdef0" // Replace your Transit Gateway ID
      }
    ]
  }

  tags = {
    "Owner" = "my-team"
  }
}
