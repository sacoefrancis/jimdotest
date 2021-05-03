# output "aws_iam_role_arn" {
#   value = "${aws_iam_role.ec2_monitoring_role.arn}"
# }


# output "lambda_function_arn" {
#   value = "${aws_lambda_function.monitor_ec2_function.arn}"
# }

output "kinesis_data_stream" {
  value = aws_kinesis_stream.kinesis_data_stream.arn
}

output "stream_consumer" {
  value = aws_instance.stream_consumer.arn
}

# output "jimbo_data_cluster" {
#   value = aws_redshift_cluster.jimbo_data_cluster.arn
# }
