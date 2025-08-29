variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "environment" {
  description = "The environment (e.g., 'dev', 'prod')."
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy the VPC in."
  type        = string
}

variable "azs" {
  description = "A list of Availability Zones to deploy into."
  type        = list(string)
}

variable "public_subnets_cidrs" {
  description = "A map of Availability Zones to public subnet CIDR blocks."
  type        = map(string)
}

variable "private_subnets_cidrs" {
  description = "A map of Availability Zones to private subnet CIDR blocks."
  type        = map(string)
}

variable "enable_nat_gateways" {
  description = "Set to false to create a single private route table for all private subnets without NAT Gateways."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC Flow Logs."
  type        = bool
  default     = true
}

variable "flow_log_retention_in_days" {
  description = "The retention period for VPC Flow Logs in CloudWatch."
  type        = number
  default     = 14
}

variable "public_routes" {
  description = "A list of custom routes for the public route table."
  type = list(object({
    cidr_block                = string
    gateway_id                = string
    nat_gateway_id            = string
    network_interface_id      = string
    vpc_peering_connection_id = string
  }))
  default = []
}

variable "private_routes" {
  description = "A map of lists of custom routes for the private route tables, keyed by AZ."
  type = map(list(object({
    cidr_block                = string
    gateway_id                = string
    nat_gateway_id            = string
    network_interface_id      = string
    vpc_peering_connection_id = string
  })))
  default = {}
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
