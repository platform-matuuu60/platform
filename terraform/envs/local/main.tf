# Local environment: every AWS call goes to Floci on loopback (docs/adr/0001).
# Start Floci first: scripts/floci.sh up

terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

locals {
  floci_endpoint = "http://127.0.0.1:4566"

  tags = {
    project     = "idp-platform"
    environment = "local"
    managed-by  = "terraform"
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  # Floci requires an endpoint for every service the configuration uses.
  endpoints {
    apigateway   = local.floci_endpoint
    apigatewayv2 = local.floci_endpoint
    cloudwatch   = local.floci_endpoint
    dynamodb     = local.floci_endpoint
    iam          = local.floci_endpoint
    lambda       = local.floci_endpoint
    logs         = local.floci_endpoint
    s3           = local.floci_endpoint
    sts          = local.floci_endpoint
  }
}

module "hello_api" {
  source = "../../modules/serverless-app"

  name       = "hello-api"
  source_dir = "${path.module}/../../../examples/hello-api/src"
  tags       = local.tags
}

# Fidelity gap: Floci reports the real AWS hostname in api_endpoint but serves
# HTTP APIs on {api_id}.execute-api.localhost.floci.io:4566.
output "hello_api_url" {
  description = "Base URL of the hello-api as served by Floci."
  value       = "http://${module.hello_api.api_id}.execute-api.localhost.floci.io:4566"
}

# Platform base: bucket where CI publishes function packages for ServerlessApps.
resource "aws_s3_bucket" "artifacts" {
  bucket = "idp-artifacts"
  tags   = local.tags
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "artifacts_bucket" {
  description = "Bucket for function packages."
  value       = aws_s3_bucket.artifacts.bucket
}
