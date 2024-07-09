variable "region" {
  default = "ca-central-1"
}

variable "vpc_id" {
  description = "The VPC ID where resources will be created"
}

variable "subnet_ids" {
  description = "List of subnets to deploy ECS tasks"
  type        = list(string)
}
