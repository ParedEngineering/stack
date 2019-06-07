variable "name" {
  description = "The name of the stack to use in security groups"
}

variable "cluster" {
  description = "The name of the ecs cluster task will be placed in"
}

variable "environment" {
  description = "The name of the environment for this stack"
}

variable "decrypt_parameters_policy_arn" {
  description = "The ARN of the policy to decrypt parameter store values"
}

resource "aws_iam_role" "task_role" {
  name               = "${var.cluster}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

# Let our task assume the ecs role
data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "allow_parameter_store_access" {
  statement {
    actions   = ["ssm:GetParameters"]
    effect    = "Allow"
    resources = ["arn:aws:ssm:*:*:parameter/${var.environment}/${var.name}/*"]
  }
}

resource "aws_iam_role_policy" "parameter_store" {
  name   = "parameter-access-task-role-policy-${var.name}-${var.environment}"
  role   = aws_iam_role.task_role.id
  policy = data.aws_iam_policy_document.allow_parameter_store_access.json
}

# Allow that role to decrypt parameters
resource "aws_iam_role_policy_attachment" "decrypt_parameters" {
  role       = aws_iam_role.task_role.name
  policy_arn = var.decrypt_parameters_policy_arn
}

# Outputs for task role
output "default_task_role_id" {
  value = aws_iam_role.task_role.id
}

output "arn" {
  value = aws_iam_role.task_role.arn
}
