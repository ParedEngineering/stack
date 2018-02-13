/**
 * This module is used to set configuration defaults for the AWS infrastructure.
 * It doesn't provide much value when used on its own because terraform makes it
 * hard to do dynamic generations of things like subnets, for now it's used as
 * a helper module for the stack.
 *
 * Usage:
 *
 *     module "defaults" {
 *       source = "github.com/segmentio/stack/defaults"
 *       region = "us-east-1"
 *       cidr   = "10.0.0.0/16"
 *     }
 *
 */

variable "region" {
  description = "The AWS region"
}

variable "cidr" {
  description = "The CIDR block to provision for the VPC"
}

variable "default_ecs_ami" {
  default = {
    us-east-1 = "ami-5e414e24"
    us-east-2 = "ami-67ab9e02"
    us-west-1 = "ami-00898660"
    us-west-2 = "ami-10ed6968"
  }
}

# http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/enable-access-logs.html#attach-bucket-policy
variable "default_log_account_ids" {
  default = {
    us-east-1 = "127311923021"
    us-east-2 = "033677994240"
    us-west-1 = "027434742980"
    us-west-2 = "797873946194"
  }
}

output "domain_name_servers" {
  value = "${cidrhost(var.cidr, 2)}"
}

output "ecs_ami" {
  value = "${lookup(var.default_ecs_ami, var.region)}"
}

output "s3_logs_account_id" {
  value = "${lookup(var.default_log_account_ids, var.region)}"
}
