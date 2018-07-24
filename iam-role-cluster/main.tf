variable "name" {
  description = "The name of the stack to use in security groups"
}

variable "environment" {
  description = "The name of the environment for this stack"
}

resource "aws_iam_role" "default_eks_cluster_role" {
  name = "eks-role-cluster-${var.name}-${var.environment}"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "eks.amazonaws.com",
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

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.default_eks_cluster_role.name}"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.default_eks_cluster_role.name}"
}

output "default_eks_cluster_role_id" {
  value = "${aws_iam_role.default_eks_cluster_role.id}"
}

output "arn" {
  value = "${aws_iam_role.default_eks_cluster_role.arn}"
}
