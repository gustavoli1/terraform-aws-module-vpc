# Terraform AWS VPC Module

This module creates a VPC in AWS with public and private subnets, NAT Gateways, and VPC Endpoints for S3 and DynamoDB.

## Features

- **Two Operational Modes**:
  - **Default (with NAT Gateways)**: Creates a highly available setup with a NAT Gateway in each Availability Zone, and a dedicated private route table for each AZ.
  - **Isolated (without NAT Gateways)**: Creates a single private route table for all private subnets, with no NAT Gateways and no default internet access.
- **Dynamic Subnet Creation**: Creates public and private subnets for each Availability Zone defined.
- **VPC Endpoints**: Automatically creates Gateway Endpoints for S3 and DynamoDB in all route tables for secure and optimized access.
- **Custom Routing**: Allows adding custom routes to both public and private route tables.
- **VPC Flow Logs**: Optional feature to enable VPC Flow Logs to CloudWatch for traffic monitoring.
- **Stable and Predictable**: Adding or removing an AZ does not recreate existing resources.

## Usage

### Default Mode (with NAT Gateways)

```hcl
module "vpc" {
  source = "./"

  project_name = "my-project"
  environment  = "dev"
  aws_region   = "us-east-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = ["us-east-1a", "us-east-1b"]

  public_subnets_cidrs = {
    "us-east-1a" = "10.0.1.0/24"
    "us-east-1b" = "10.0.2.0/24"
  }

  private_subnets_cidrs = {
    "us-east-1a" = "10.0.101.0/24"
    "us-east-1b" = "10.0.102.0/24"
  }
}
```

### Isolated Mode (without NAT Gateways)

To use this mode, set `enable_nat_gateways = false`.

```hcl
module "vpc" {
  source = "./"

  project_name = "my-isolated-project"
  environment  = "dev"
  aws_region   = "us-east-1"

  enable_nat_gateways = false

  vpc_cidr = "10.1.0.0/16"
  azs      = ["us-east-1a", "us-east-1b"]

  public_subnets_cidrs = {
    "us-east-1a" = "10.1.1.0/24"
    "us-east-1b" = "10.1.2.0/24"
  }

  private_subnets_cidrs = {
    "us-east-1a" = "10.1.101.0/24"
    "us-east-1b" = "10.1.102.0/24"
  }
}
```

## Managing Custom Routes

You can add or remove custom routes by defining them in the `public_routes` and `private_routes` variables.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| vpc_cidr | The CIDR block for the VPC. | `string` | - | yes |
| project_name | The name of the project. | `string` | - | yes |
| environment | The environment (e.g., 'dev', 'prod'). | `string` | - | yes |
| aws_region | The AWS region to deploy the VPC in. | `string` | - | yes |
| azs | A list of Availability Zones to deploy into. | `list(string)` | - | yes |
| public_subnets_cidrs | A map of Availability Zones to public subnet CIDR blocks. | `map(string)` | - | yes |
| private_subnets_cidrs | A map of Availability Zones to private subnet CIDR blocks. | `map(string)` | - | yes |
| enable_nat_gateways | Set to false to create a single private route table for all private subnets without NAT Gateways. | `bool` | `true` | no |
| enable_flow_logs | Whether to enable VPC Flow Logs. | `bool` | `true` | no |
| flow_log_retention_in_days | The retention period for VPC Flow Logs in CloudWatch. | `number` | `14` | no |
| public_routes | A list of custom routes for the public route table. | `list(object)` | `[]` | no |
| private_routes | A map of lists of custom routes for the private route tables, keyed by AZ or `"single"`. | `map(list(object))` | `{}` | no |
| tags | A map of tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC. |
| public_subnet_ids | The IDs of the public subnets. |
| private_subnet_ids | The IDs of the private subnets. |
| public_route_table_id | The ID of the public route table. |
| private_route_table_ids | The IDs of the private route tables. |
