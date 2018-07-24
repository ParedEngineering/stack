variable "name" {
  description = "The name of the stack to use in security groups"
}

variable "environment" {
  description = "The name of the environment for this stack"
}

resource "aws_iam_role" "default_eks_node_role" {
  name = "eks-role-node-${var.name}-${var.environment}"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com",
          "ssm.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.default_eks_node_role.name}"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.default_eks_node_role.name}"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.default_eks_node_role.name}"
}

resource "aws_iam_instance_profile" "eks_node" {
  name = "eks-instance-profile-${var.name}-${var.environment}"
  path = "/"
  role = "${aws_iam_role.default_eks_node_role.name}"
}

output "default_eks_node_role_id" {
  value = "${aws_iam_role.default_eks_node_role.id}"
}

output "arn" {
  value = "${aws_iam_role.default_eks_node_role.arn}"
}

output "profile" {
  value = "${aws_iam_instance_profile.eks_node.id}"
}
