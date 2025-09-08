locals {
    region = "us-east-1"	// Replace for your Region       
}

provider "aws" {
  region = local.region
}

module "vpc" {
  source = "../"

  project_name = "vpc-egress"
  environment  = "live"
  aws_region   = local.region
  
  enable_nat_gateways = false 
  enable_flow_logs = true

  vpc_cidr = "10.0.0.0/16"
  azs      = = ["${local.region}a", "${local.region}b", "${local.region}c"]

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
  
  tags = {
    "Owner" = "my-team"
  }
}
