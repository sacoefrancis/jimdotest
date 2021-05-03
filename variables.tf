# variable "lambda_role_name" {
# 	default = "lambda_role_for_monitoring"
# 	description = "IAM role for lambda"
# }

# variable "lambda_role_policy" {
# 	default = "ec2_monitoring_policy"
# 	description = "IAM role policy"
# }

# variable "lambda_function_name" {
# 	default = "monitoring_ec2_status"
# 	description = "lambda function name"
# }

# variable "lambda_file_name" {
# 	default = "ec2_monitoring_function"
# 	description = "lambda file name"
# }


variable "aws_region" {
  default     = "us-east-1"
  description = "sender aws region"
}

variable "kinesis_stream_name" {
  default     = "jimbo_stream"
  description = "name of the stream"
}

variable "shard_count" {
  default     = 1
  description = "number of shard count"
}

variable "ami" {
  default     = "ami-048f6ed62451373d9"
  description = "os for ec2 instance"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "type of instance"
}

variable "key_pair_name" {
  default     = "test_cloudwatch"
  description = "pem file name "
}

variable "credential_file_path" {
  default     = "~/.aws/credentials"
  description = "aws credentials path"
}

variable "ec2_instance_name" {
  default     = "stream_consumer"
  description = "name of the ec2 instance"
}

variable "redshift_cluster_name" {
  default     = "jimbodatacluster"
  description = "name of the redshift cluster"
}

variable "database_name" {
  default     = "dev"
  description = "database name"
}

variable "db_username" {
  default     = "awsuser"
  description = "database username"
}

variable "db_password" {
  default     = "Admin123"
  description = "database password"
}

variable "redshift_node_type" {
  default     = "dc2.large"
  description = "Type of the cluster instance"
}

variable "redshift_cluster_type" {
  default     = "single-node"
  description = "type of redshift cluster"
}

variable "consumer_limit" {
  default     = 5
  description = "number of records to consume at a time"
}

variable "consumer_name" {
  default     = "sample"
  description = "name of the consumer"
}

variable "bucket_name" {
  default     = "jimbointerviewbucket"
  description = "name of the bucket"
}

variable "redshift_role_name" {
  default     = "redshift_cluster_s3_role"
  description = "redshift role to access the cluster"
}

variable "redshift_permission_policy" {
  default     = "redshift_s3_permission_policy"
  description = "redshift and s3 permission policy"
}

variable "cross_profile" {
  default     = "prod"
  description = "profile of the remote account"
}