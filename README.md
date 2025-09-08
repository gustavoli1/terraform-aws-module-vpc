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

When NAT gateways are enabled, a separate route table is created for each Availability Zone. You must specify the routes for each AZ. In this scenario, you would typically route specific internal CIDR blocks to the Transit Gateway, while the default route (`0.0.0.0/0`) would point to the NAT Gateway for internet access.

```hcl
module "vpc" {
  # ... other variables
  enable_nat_gateways = true

  private_routes = {
    "us-east-1a" = [
      {
        cidr_block         = "172.16.0.0/16" # Example: Route internal network to TGW
        transit_gateway_id = "tgw-1234567890abcdef0" // Replace your Transit Gateway ID
      }
    ],
    "us-east-1b" = [
      {
        cidr_block         = "172.16.0.0/16" # Example: Route internal network to TGW
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

## 🔗 Transit Gateway Attachment

This module can automatically attach the VPC to a Transit Gateway, which is especially useful when the Transit Gateway is shared with your account via AWS RAM.

To enable this, set `attach_to_transit_gateway = true` and provide the Transit Gateway ID.

```hcl
module "vpc_with_tgw_attachment" {
  source = "./"

  # ... other variables

  # Attach to Transit Gateway
  attach_to_transit_gateway = true
  transit_gateway_id        = "tgw-0123456789abcdef0" # <-- Replace with your TGW ID

  # Optional: Specify subnets for the attachment.
  # If omitted, the private subnets will be used by default.
  # transit_gateway_attachment_subnet_ids = [
  #   module.vpc_with_tgw_attachment.private_subnet_ids[0],
  #   module.vpc_with_tgw_attachment.private_subnet_ids[1],
  # ]
}
```

### ⚠️ Important Note on Attachment Recreation

To prevent errors when removing an Availability Zone, this module uses a `create_before_destroy` lifecycle policy for the Transit Gateway attachment. This means that when you remove an AZ from your configuration, the existing attachment will be destroyed and a new one will be created with an updated list of subnets.

This has an important implication: **the new attachment will have a new ID**.

*   If you use **route propagation** in your Transit Gateway route table, the route to the VPC should be updated automatically.
*   If you use **static routes** in your Transit Gateway route table that point to the attachment ID, you will need to **manually update the route** to point to the new attachment ID after the changes are applied.

*For a complete, working example, see the `examples/example_with_transit_gateway.tf` file.*

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
| `attach_to_transit_gateway` | Set to `true` to attach the VPC to a Transit Gateway. | `bool` | `false` | No |
| `transit_gateway_id` | The ID of the Transit Gateway to attach to. | `string` | `""` | No |
| `transit_gateway_attachment_subnet_ids` | Subnets to use for the TGW attachment. Defaults to private subnets. | `list(string)` | `[]` | No |

### 📤 Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | The ID of the created VPC. |
| `public_subnet_ids` | The IDs of the public subnets. |
| `private_subnet_ids`| The IDs of the private subnets. |
| `public_route_table_id`| The ID of the public route table. |
| `private_route_table_ids`| The IDs of the private route tables. |
| `transit_gateway_attachment_id` | The ID of the Transit Gateway attachment. |

---

## 🤝 Contributions

Feel free to open pull requests or report issues. All contributions are welcome! ❤️
