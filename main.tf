terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region                  = var.aws_region
  shared_credentials_file = var.credential_file_path
  profile                 = "default"
  alias                   = "default"
}

provider "aws" {
  region                  = var.aws_region
  shared_credentials_file = var.credential_file_path
  profile                 = "prod"
  alias                   = "prod"
}

# resource "aws_iam_role" "redshift_role" {
#   provider = aws.prod
#   name     = var.redshift_role_name
#   # assume_role_policy = data.template_file.iam_assume_policy.rendered
#   assume_role_policy = templatefile("${path.module}/iam_assume_policy.tpl", {
#     aws_region            = var.aws_region,
#     redshift_cluster_name = var.redshift_cluster_name,
#     db_username           = var.db_username
#   })
# }

# resource "aws_iam_role_policy" "redshit_s3_policy" {
#   provider = aws.prod
#   name     = var.redshift_permission_policy
#   role     = aws_iam_role.redshift_role.id
#   policy   = file("${path.module}/iam_permission_policy.json")
# }

# data "template_file" "user_data" {
#   template = file("${path.module}/user_data.tpl")
#   vars = {
#     limit = var.consumer_limit
#     stream_name = var.kinesis_stream_name
#     stream_arn = aws_kinesis_stream.kinesis_data_stream.arn
#     consumer_name = var.consumer_name
#     bucket_name = var.bucket_name
#     aws_profile = var.cross_profile
#   }
# }

# data "template_file" "iam_assume_policy" {
#   template = file("${path.module}/iam_assume_policy.tpl")
#   vars = {
#     aws_region = var.aws_region
#     redshift_cluster_name = var.redshift_cluster_name
#     db_username = var.db_username
#   }
# }

resource "aws_kinesis_stream" "kinesis_data_stream" {
  provider                  = aws.default
  name                      = var.kinesis_stream_name
  shard_count               = var.shard_count
  enforce_consumer_deletion = true
}

resource "aws_instance" "stream_consumer" {
  provider      = aws.default
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_pair_name
  user_data = templatefile("${path.module}/user_data.tpl", {
    limit         = var.consumer_limit,
    stream_name   = var.kinesis_stream_name,
    stream_arn    = aws_kinesis_stream.kinesis_data_stream.arn,
    consumer_name = var.consumer_name,
    bucket_name   = var.bucket_name,
    aws_profile   = var.cross_profile
  })
  tags = {
    Name = var.ec2_instance_name
  }
}

# resource "aws_redshift_cluster" "jimbo_data_cluster" {
#   provider            = aws.prod
#   cluster_identifier  = var.redshift_cluster_name
#   database_name       = var.database_name
#   master_username     = var.db_username
#   master_password     = var.db_password
#   node_type           = var.redshift_node_type
#   cluster_type        = var.redshift_cluster_type
#   skip_final_snapshot = true
#   iam_roles           = [aws_iam_role.redshift_role.id]
#   publicly_accessible = false
# }



# data "archive_file" "lambda_zip" {
#   type        = "zip"
#   source_dir  = "${path.module}/tmp"
#   output_path = "${path.module}/lambda_function/${var.lambda_file_name}.zip"
# }


# resource "aws_lambda_function" "monitor_ec2_function" {
#   function_name     = "${var.lambda_function_name}"
#   filename          = "${path.module}/lambda_function/${var.lambda_file_name}.zip"
#   source_code_hash  = data.archive_file.lambda_zip.output_base64sha256
#   role              = aws_iam_role.ec2_monitoring_role.arn
#   runtime           = "python3.7"
#   handler           = "ec2_monitoring_function.lambda_handler"
#   timeout           = "60"
#   publish           = true

#   environment {
#     variables = {
#       SENDER = "${var.sender_mail}",
#       RECIPIENTS = "${var.recipient_mails}",
#       SENDER_AWS_REGION = "${var.aws_region}"
#     }
#   }
# }


# resource "aws_cloudwatch_event_rule" "monitor_ec2_rule" {
#   name = "${var.cloud_watch_rule_name}"
#   description = "monitor ec2 status changes"
#   event_pattern = file("${path.module}/policy/event_pattern.json")
# }


# resource "aws_cloudwatch_event_target" "cloudwatch_target" {
#     rule = aws_cloudwatch_event_rule.monitor_ec2_rule.name
#     arn = aws_lambda_function.monitor_ec2_function.arn
#     depends_on = [aws_lambda_function.monitor_ec2_function]
# }


# resource "aws_lambda_permission" "allow_cloudwatch_to_call" {
#   statement_id = "AllowExecutionFromCloudWatch"
#   action = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.monitor_ec2_function.function_name
#   principal = "events.amazonaws.com"
#   source_arn = aws_cloudwatch_event_rule.monitor_ec2_rule.arn
# }