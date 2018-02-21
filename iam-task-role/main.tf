variable "name" {
  description = "The name of the stack to use in security groups"
}

variable "environment" {
  description = "The name of the environment for this stack"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role-${var.name}-${var.environment}"
  assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
     {
       "Sid": "",
       "Effect": "Allow",
       "Principal": {
         "Service": "ecs-tasks.amazonaws.com"
       },
       "Action": "sts:AssumeRole"
     }
   ]
 }
EOF
}

# We should eventually move to stricter config access policy
resource "aws_iam_role_policy" "default_ecs_task_role_policy" {
  name = "ecs-task-role-policy-${var.name}-${var.environment}"
  role = "${aws_iam_role.ecs_task_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads"],
      "Resource": "arn:aws:s3:::pared-config/*"
    }
  ]
}
EOF
}




# Outputs for task role
output "default_ecs_task_role_id" {
  value = "${aws_iam_role.ecs_task_role.id}"
}

output "arn" {
  value = "${aws_iam_role.ecs_task_role.arn}"
}