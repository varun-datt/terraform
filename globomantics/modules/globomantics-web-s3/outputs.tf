output "s3_bucket" {
  value       = aws_s3_bucket.webapp
  description = "s3 bucket for webapp"
}

output "instance_profile" {
  value       = aws_iam_instance_profile.nginx
  description = "instance profile"
}
