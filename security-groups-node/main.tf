/**
 * Creates security groups to be used by EKS nodes
 */

variable "name" {
  description = "The name of the security groups serves as a prefix, e.g stack"
}

variable "cluster_name" {
  description = "The name given to the EKS cluster"
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

variable "cluster_security_group_id" {
  description = "The ID of the primary cluster security group"
}

resource "aws_security_group" "node" {
  name        = "${format("%s-%s-node", var.name, var.environment)}"
  vpc_id      = "${var.vpc_id}"
  description = "Node in cluster communication"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = "${
    map(
     "Name", "${format("%s cluster", var.name)}",
     "Environment", "${var.environment}",
     "kubernetes.io/cluster/${var.cluster_name}", "owned"
    )
  }"
}

resource "aws_security_group_rule" "cluster_node_self_ingress" {
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.node.id}"
  source_security_group_id = "${aws_security_group.node.id}"
  to_port                  = 65535
  type                     = "ingress"
  description              = "Allows nodes to communicate with each other"
}

resource "aws_security_group_rule" "cluster_node_control_plane_ingress" {
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.node.id}"
  source_security_group_id = "${var.cluster_security_group_id}"
  to_port                  = 65535
  type                     = "ingress"
  description              = "Allows communication from control plane"
}

resource "aws_security_group_rule" "node_to_cluster_ingress" {
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${var.cluster_security_group_id}"
  source_security_group_id = "${aws_security_group.node.id}"
  to_port                  = 443
  type                     = "ingress"
  description              = "Allows pods to communicate with the cluster API server"
}

resource "aws_security_group_rule" "ssh_to_node_ingress" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.node.id}"
  to_port           = 22
  type              = "ingress"
  description       = "Allows developers to SSH into nodes"
}

output "node" {
  value = "${aws_security_group.node.id}"
}
