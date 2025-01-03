terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# terraform code to deploy an s3 bucket
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "thirteenteeth"
  tags = {
    Name = "thirteenteeth"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.s3_bucket.bucket
}
