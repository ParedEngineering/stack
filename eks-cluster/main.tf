variable "name" {
  description = "The cluster name, e.g cdn"
}

variable "environment" {
  description = "Environment tag, e.g prod"
}

variable "cluster_role_arn" {
  description = "Role ARN for the cluster"
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = "list"
}

variable "instance_type" {
  description = "The instance type to use, e.g t2.small"
}

variable "image_id" {
  description = "AMI Image ID"
}

variable "security_groups" {
  description = "Comma separated list of security groups"
  type        = "list"
}

variable "node_security_group_id" {
  description = "Node Security Group ID"
}

variable "iam_instance_profile" {
  description = "Instance profile ARN to use in the launch configuration"
}

variable "region" {
  description = "AWS Region"
}

variable "availability_zones" {
  description = "List of AZs"
  type        = "list"
}

variable "key_name" {
  description = "SSH key name to use"
}

variable "instance_ebs_optimized" {
  description = "When set to true the instance will be launched with EBS optimized turned on"
  default     = true
}

variable "min_size" {
  description = "Minimum instance count"
  default     = 3
}

variable "max_size" {
  description = "Maxmimum instance count"
  default     = 100
}

variable "desired_capacity" {
  description = "Desired instance count"
  default     = 3
}

variable "associate_public_ip_address" {
  description = "Should created instances be publicly accessible (if the SG allows)"
  default     = false
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  default     = 25
}

resource "aws_eks_cluster" "main" {
  name     = "${var.name}"
  role_arn = "${var.cluster_role_arn}"

  vpc_config {
    security_group_ids = ["${var.security_groups}"]
    subnet_ids         = ["${var.subnet_ids}"]
  }
}

data "template_file" "eks_cloud_config" {
  template = "${file("${path.module}/files/cloud-config.yml.tpl")}"

  vars {
    environment                   = "${var.environment}"
    name                          = "${var.name}"
    region                        = "${var.region}"
    endpoint                      = "${aws_eks_cluster.main.endpoint}"
    cluster_name                  = "${aws_eks_cluster.main.name}"
    cluster_certificate_authority = "${aws_eks_cluster.main.certificate_authority.0.data}"
  }
}

data "template_cloudinit_config" "cloud_config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.eks_cloud_config.rendered}"
  }
}

resource "aws_launch_configuration" "main" {
  name_prefix = "${format("%s-", var.name)}"

  image_id                    = "${var.image_id}"
  instance_type               = "${var.instance_type}"
  ebs_optimized               = "${var.instance_ebs_optimized}"
  iam_instance_profile        = "${var.iam_instance_profile}"
  security_groups             = ["${var.node_security_group_id}"]
  user_data                   = "${data.template_cloudinit_config.cloud_config.rendered}"
  associate_public_ip_address = "${var.associate_public_ip_address}"
  key_name                    = "${var.key_name}"

  # root
  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.root_volume_size}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "main" {
  name = "${var.name}"

  availability_zones   = ["${var.availability_zones}"]
  vpc_zone_identifier  = ["${var.subnet_ids}"]
  launch_configuration = "${aws_launch_configuration.main.id}"
  min_size             = "${var.min_size}"
  max_size             = "${var.max_size}"
  desired_capacity     = "${var.desired_capacity}"
  termination_policies = ["OldestLaunchConfiguration", "Default"]

  tag {
    key                 = "Name"
    value               = "${var.name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Cluster"
    value               = "${var.name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${aws_eks_cluster.main.name}"
    value               = "owned"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "endpoint" {
  value = "${aws_eks_cluster.main.endpoint}"
}

output "kubeconfig-certificate-authority-data" {
  value = "${aws_eks_cluster.main.certificate_authority.0.data}"
}

output "name" {
  value = "${aws_eks_cluster.main.name}"
}
