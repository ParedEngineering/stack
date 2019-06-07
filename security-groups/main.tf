/**
 * Creates basic security groups to be used by instances and ELBs.
 */

variable "name" {
  description = "The name of the security groups serves as a prefix, e.g stack"
}

variable "vpc_id" {
  description = "The VPC ID"
}

variable "environment" {
  description = "The environment, used for tagging, e.g prod"
}

variable "cidr" {
  description = "The cidr block to use for internal security groups"
}

resource "aws_security_group" "cluster" {
  name        = format("%s-%s-cluster", var.name, var.environment)
  vpc_id      = var.vpc_id
  description = "Cluster communication"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags {
    Name        = format("%s cluster", var.name)
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "local_to_cluster_ingress" {
  cidr_blocks       = ["136.25.190.72/32"]
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.cluster.id
  to_port           = 443
  type              = "ingress"
  description       = "Allows local machine to communicate with cluster API"
}

output "cluster" {
  value = aws_security_group.cluster.id
}
