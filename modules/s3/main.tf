terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
  }
}

resource "aws_s3_bucket" "alb_logs" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name = "ALBLogsBucket"
  }
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "delete_all"
    status = "Enabled"

    expiration {
      days = 1
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::127311923021:root"
        },
        Action   = "s3:PutObject",
        Resource = "arn:aws:s3:::${var.bucket_name}/AWSLogs/935221134767/*"
      }
    ]
  })
}