/**
 * The stack module combines sub modules to create a complete
 * stack with `vpc`, a default eks cluster with auto scaling
 * Also installs the SSM agent rather than a bastion
 *
 * Usage:
 *
 *    module "stack" {
 *      source      = "github.com/segmentio/stack"
 *      name        = "mystack"
 *      environment = "prod"
 *    }
 *
 */

variable "name" {
  description = "the name of your stack, e.g. \"segment\""
}

variable "environment" {
  description = "the name of your environment, e.g. \"prod-west\""
}

variable "key_name" {
  description = "the name of the ssh key to use, e.g. \"internal-key\""
}

variable "domain_name" {
  description = "the internal DNS name to use with services"
  default     = "stack.local"
}

variable "domain_name_servers" {
  description = "the internal DNS servers, defaults to the internal route53 server of the VPC"
  default     = ""
}

variable "region" {
  description = "the AWS region in which resources are created, you must set the availability_zones variable as well if you define this value to something other than the default"
  default     = "us-east-1"
}

variable "cidr" {
  description = "the CIDR block to provision for the VPC, if set to something other than the default, both internal_subnets and external_subnets have to be defined as well"
  default     = "10.30.0.0/16"
}

variable "internal_subnets" {
  description = "a list of CIDRs for internal subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones"
  default     = ["10.30.0.0/19", "10.30.64.0/19", "10.30.128.0/19"]
  type        = "list"
}

variable "external_subnets" {
  description = "a list of CIDRs for external subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones"
  default     = ["10.30.32.0/20", "10.30.96.0/20", "10.30.160.0/20"]
  type        = "list"
}

variable "availability_zones" {
  description = "a comma-separated list of availability zones, defaults to all AZ of the region, if set to something other than the defaults, both internal_subnets and external_subnets have to be defined as well"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
  type        = "list"
}

variable "eks_cluster_name" {
  description = "the name of the cluster, if not specified the variable name will be used"
  default     = ""
}

variable "eks_instance_type" {
  description = "the instance type to use for your default eks cluster"
  default     = "m5.large"
}

variable "eks_instance_ebs_optimized" {
  description = "use EBS - not all instance types support EBS"
  default     = false
}

variable "eks_min_size" {
  description = "the minimum number of instances to use in the default eks cluster"

  // create 3 instances in our cluster by default
  // 2 instances to run our service with high-availability
  // 1 extra instance so we can deploy without port collisions
  default = 3
}

variable "eks_max_size" {
  description = "the maximum number of instances to use in the default eks cluster"
  default     = 6
}

variable "eks_desired_capacity" {
  description = "the desired number of instances to use in the default eks cluster"
  default     = 3
}

variable "eks_root_volume_size" {
  description = "the size of the eks instance root volume"
  default     = 25
}

variable "eks_security_groups" {
  description = "A comma separated list of security groups from which ingest traffic will be allowed on the eks cluster, it defaults to allowing ingress traffic on port 22 and coming from the ELBs"
  default     = ""
}

variable "eks_ami" {
  description = "The AMI that will be used to launch EC2 instances in the eks cluster"
  default     = ""
}

variable "logs_expiration_enabled" {
  default = false
}

variable "logs_expiration_days" {
  default = 30
}

variable "zone_arns" {
  description = "Zone arn of the hosted zone where this cluster manages DNS entries"
  type        = "list"
}

module "defaults" {
  source = "./defaults"
  region = "${var.region}"
  cidr   = "${var.cidr}"
}

module "vpc" {
  source             = "./vpc"
  name               = "${var.name}"
  cidr               = "${var.cidr}"
  internal_subnets   = "${var.internal_subnets}"
  external_subnets   = "${var.external_subnets}"
  availability_zones = "${var.availability_zones}"
  environment        = "${var.environment}"
  cluster_name       = "${coalesce(var.eks_cluster_name, var.name)}"
}

module "security_groups" {
  source      = "./security-groups"
  name        = "${var.name}"
  vpc_id      = "${module.vpc.id}"
  environment = "${var.environment}"
  cidr        = "${var.cidr}"
}

module "security_groups_node" {
  source                    = "./security-groups-node"
  name                      = "${var.name}"
  vpc_id                    = "${module.vpc.id}"
  environment               = "${var.environment}"
  cidr                      = "${var.cidr}"
  cluster_security_group_id = "${module.security_groups.cluster}"
  cluster_name              = "${coalesce(var.eks_cluster_name, var.name)}"
}

module "iam_role_cluster" {
  source      = "iam-role-cluster"
  name        = "${var.name}"
  environment = "${var.environment}"
}

module "iam_role_node" {
  source      = "iam-role-node"
  name        = "${var.name}"
  environment = "${var.environment}"
  zone_arns   = "${var.zone_arns}"
}

module "eks_cluster" {
  source                 = "./eks-cluster"
  cluster_role_arn       = "${module.iam_role_cluster.arn}"
  name                   = "${coalesce(var.eks_cluster_name, var.name)}"
  environment            = "${var.environment}"
  image_id               = "${coalesce(var.eks_ami, module.defaults.eks_ami)}"
  subnet_ids             = "${module.vpc.internal_subnets}"
  key_name               = "${var.key_name}"
  instance_type          = "${var.eks_instance_type}"
  instance_ebs_optimized = "${var.eks_instance_ebs_optimized}"
  iam_instance_profile   = "${module.iam_role_node.profile}"
  min_size               = "${var.eks_min_size}"
  max_size               = "${var.eks_max_size}"
  desired_capacity       = "${var.eks_desired_capacity}"
  region                 = "${var.region}"
  availability_zones     = "${module.vpc.availability_zones}"
  root_volume_size       = "${var.eks_root_volume_size}"
  security_groups        = ["${module.security_groups.cluster}"]
  node_security_group_id = "${module.security_groups_node.node}"
}

module "s3_logs" {
  source                  = "./s3-logs"
  name                    = "${var.name}"
  environment             = "${var.environment}"
  account_id              = "${module.defaults.s3_logs_account_id}"
  logs_expiration_enabled = "${var.logs_expiration_enabled}"
  logs_expiration_days    = "${var.logs_expiration_days}"
}

// The region in which the infra lives.
output "region" {
  value = "${var.region}"
}

// Comma separated list of internal subnet IDs.
output "internal_subnets" {
  value = "${module.vpc.internal_subnets}"
}

// Comma separated list of external subnet IDs.
output "external_subnets" {
  value = "${module.vpc.external_subnets}"
}

// eks Service IAM role.
output "iam_role" {
  value = "${module.iam_role_cluster.arn}"
}

// Default eks role ID. Useful if you want to add a new policy to that role.
output "iam_role_default_eks_role_id" {
  value = "${module.iam_role_cluster.default_eks_cluster_role_id}"
}

// S3 bucket ID for ELB logs.
output "log_bucket_id" {
  value = "${module.s3_logs.id}"
}

// The environment of the stack, e.g "prod".
output "environment" {
  value = "${var.environment}"
}

// The default eks cluster name.
output "cluster" {
  value = "${module.eks_cluster.name}"
}

// The VPC availability zones.
output "availability_zones" {
  value = "${module.vpc.availability_zones}"
}

// The VPC security group ID.
output "vpc_security_group" {
  value = "${module.vpc.security_group}"
}

// The VPC ID.
output "vpc_id" {
  value = "${module.vpc.id}"
}

// Comma separated list of internal route table IDs.
output "internal_route_tables" {
  value = "${module.vpc.internal_rtb_id}"
}

// The external route table ID.
output "external_route_tables" {
  value = "${module.vpc.external_rtb_id}"
}
