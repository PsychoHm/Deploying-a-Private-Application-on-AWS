output "alb_logs_bucket_name" {
  value = aws_s3_bucket.alb_logs.bucket
}

output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.alb_logs.bucket
}