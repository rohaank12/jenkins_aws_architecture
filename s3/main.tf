provider "aws" {
  region = "ap-south-1" # Replace with your desired region
}

# Create S3 bucket
resource "aws_s3_bucket" "example_bucket" {
  bucket = "wezvatech-jenkins-backup-9739110917"
}

# Enable versioning
resource "aws_s3_bucket_versioning" "example_versioning" {
  bucket = aws_s3_bucket.example_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Create lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "example_lifecycle" {
  bucket = aws_s3_bucket.example_bucket.id

  rule {
    id     = "lifecycle-policy"
    status = "Enabled"

    # Transition objects to STANDARD_IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition objects to GLACIER after 365 days
    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    # Expire objects after 2 years
    expiration {
      days = 730
    }

    # Manage noncurrent versions of objects
    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 180
    }
  }
}
