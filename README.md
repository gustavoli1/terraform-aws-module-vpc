# 🚀 Terraform AWS VPC Module ☁️

This is a robust and flexible Terraform module for creating a Virtual Private Cloud (VPC) on AWS. It has been designed to be the foundation of your infrastructure, with a focus on security, high availability, and best practices.

---

## ✨ Features

*   **✌️ Two Operational Modes:**
    *   **Default (with NATs):** Creates a high-availability architecture with a NAT Gateway per Availability Zone (AZ), ideal for production environments.
    *   **Isolated (no NATs):** Creates private subnets with no internet access, using a single route table, perfect for lab environments or more secure networks.
*   **🗺️ Dynamic Subnets:** Creates public and private subnets in all the AZs you define.
*   **🔒 VPC Endpoints:** Automatically aconfigures Gateway Endpoints for S3 and DynamoDB, ensuring that traffic to these services does not leave the AWS network, which increases security and reduces costs.
*   **🔄 Customizable Routing:** Allows you to add your own custom routes to both public and private route tables.
*   **📊 VPC Flow Logs:** Includes an option to enable traffic logs to be sent to CloudWatch, essential for monitoring and auditing.
*   **💪 Stable & Predictable:** Adding or removing AZs does not cause the recreation of existing resources, only the necessary additions or removals.

---

## 🛠️ How to Use

### 🏗️ Default Mode (Recommended for Production)

This mode creates the complete architecture with NAT Gateways to allow private subnets to access the internet.

```hcl
module "vpc_prod" {
  source = "./"

  project_name = "my-awesome-project"
  environment  = "production"
  aws_region   = "us-east-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = ["us-east-1a", "us-east-1b"]

  public_subnets_cidrs = {
    "us-east-1a" = "10.0.1.0/24",
    "us-east-1b" = "10.0.2.0/24",
  }

  private_subnets_cidrs = {
    "us-east-1a" = "10.0.101.0/24",
    "us-east-1b" = "10.0.102.0/24",
  }
}
```

### 🔬 Isolated Mode (For Labs or Secure Networks)

To use this mode, simply set `enable_nat_gateways = false`. Ideal for when private subnets do not require internet access.

```hcl
module "vpc_lab" {
  source = "./"

  project_name = "my-lab"
  environment  = "dev"
  aws_region   = "us-east-1"

  enable_nat_gateways = false // The magic happens here!

  vpc_cidr = "10.1.0.0/16"
  azs      = ["us-east-1a", "us-east-1b"]

  public_subnets_cidrs = {
    "us-east-1a" = "10.1.1.0/24",
    "us-east-1b" = "10.1.2.0/24",
  }

  private_subnets_cidrs = {
    "us-east-1a" = "10.1.101.0/24",
    "us-east-1b" = "10.1.102.0/24",
  }
}
```

---

## 🔄 Custom Routing

You can add custom routes to both the public and private route tables using the `public_routes` and `private_routes` variables. This is useful for directing traffic to a specific appliance, a VPC peering connection, or a Transit Gateway.

The route object accepts the following attributes:
- `cidr_block`: The destination CIDR block.
- `gateway_id`: The ID of an Internet Gateway or Virtual Private Gateway.
- `nat_gateway_id`: The ID of a NAT Gateway.
- `network_interface_id`: The ID of a network interface.
- `vpc_peering_connection_id`: The ID of a VPC peering connection.
- `transit_gateway_id`: The ID of a Transit Gateway.

### Example: Routing to a Transit Gateway

To route traffic to a Transit Gateway, you can add a route to the `private_routes` variable. The structure of this variable depends on whether NAT gateways are enabled.

#### With `enable_nat_gateways = true` (Default)

When NAT gateways are enabled, a separate route table is created for each Availability Zone. You must specify the routes for each AZ.

```hcl
module "vpc" {
  # ... other variables
  enable_nat_gateways = true

  private_routes = {
    "us-east-1a" = [
      {
        cidr_block         = "0.0.0.0/0"
        transit_gateway_id = "tgw-1234567890abcdef0" // Replace your Transit Gateway ID
      }
    ],
    "us-east-1b" = [
      {
        cidr_block         = "0.0.0.0/0"
        transit_gateway_id = "tgw-1234567890abcdef0" // Replace your Transit Gateway ID
      }
    ]
  }
}
```
*For a complete, working example, see the `examples/example_with_nat.tf` file.*

#### With `enable_nat_gateways = false`

When NAT gateways are disabled, a single route table is used for all private subnets. You must use the key `"single"` to specify the routes.

```hcl
module "vpc" {
  # ... other variables
  enable_nat_gateways = false

  private_routes = {
    "single" = [
      {
        cidr_block         = "0.0.0.0/0" 
        transit_gateway_id = "tgw-1234567890abcdef0" // Replace your Transit Gateway ID
      }
    ]
  }
}
```
*For a complete, working example, see the `examples/example.tf` file.*

---

## 📖 Variable Dictionary (Inputs & Outputs)

### 📥 Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| `vpc_cidr` | The main CIDR block for the VPC. | `string` | - | **Yes** |
| `project_name` | The name of your project (used in tags). | `string` | - | **Yes** |
| `environment` | The environment (e.g., 'dev', 'prod'). | `string` | - | **Yes** |
| `aws_region` | The AWS region where the VPC will be created. | `string` | - | **Yes** |
| `azs` | A list of the Availability Zones. | `list(string)` | - | **Yes** |
| `public_subnets_cidrs` | Map of AZs to public subnet CIDRs. | `map(string)` | - | **Yes** | 
| `private_subnets_cidrs`| Map of AZs to private subnet CIDRs. | `map(string)` | - | **Yes** |
| `enable_nat_gateways`| Set to `false` for isolated mode. | `bool` | `true` | No |
| `enable_flow_logs` | Enables or disables VPC Flow Logs. | `bool` | `true` | No |
| `flow_log_retention` | Log retention period (in days). | `number` | `14` | No |
| `public_routes` | List of custom routes for the public route table. See [Custom Routing](#-custom-routing) section for details. | `list(object)` | `[]` | No |
| `private_routes` | Map of custom routes for the private route tables. See [Custom Routing](#-custom-routing) section for details. | `map(list(object))` | `{}` | No |
| `tags` | Additional tags to apply to all resources. | `map(string)` | `{}` | No |

### 📤 Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | The ID of the created VPC. |
| `public_subnet_ids` | The IDs of the public subnets. |
| `private_subnet_ids`| The IDs of the private subnets. |
| `public_route_table_id`| The ID of the public route table. |
| `private_route_table_ids`| The IDs of the private route tables. |

---

## 🤝 Contributions

Feel free to open pull requests or report issues. All contributions are welcome! ❤️
