# =============================================================================
# Cloud-Native E-Commerce Infrastructure
# Terraform configuration for AWS deployment
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment to use S3 backend for state management
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "cloud-native-ecommerce/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# =============================================================================
# Variables
# =============================================================================

variable "domain_name" {
  description = "The domain name for the application"
  type        = string
  default     = "ecommerce.veeracs.info"
}

variable "root_domain" {
  description = "The root domain (for Route53 hosted zone lookup)"
  type        = string
  default     = "veeracs.info"
}

variable "aws_region" {
  description = "AWS region for resources (except CloudFront/ACM which use us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "cloud-native-ecommerce"
}

# =============================================================================
# Providers
# =============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Provider for ACM certificates (must be us-east-1 for CloudFront)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# =============================================================================
# Data Sources
# =============================================================================

# Look up the existing Route53 hosted zone
data "aws_route53_zone" "main" {
  name         = var.root_domain
  private_zone = false
}

# =============================================================================
# S3 Buckets for Static Assets
# =============================================================================

# Shell (Host) application bucket
resource "aws_s3_bucket" "shell" {
  bucket = "${var.project_name}-shell-${var.environment}"
}

resource "aws_s3_bucket_public_access_block" "shell" {
  bucket = aws_s3_bucket.shell.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "shell" {
  bucket = aws_s3_bucket.shell.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Products Remote bucket
resource "aws_s3_bucket" "products" {
  bucket = "${var.project_name}-products-${var.environment}"
}

resource "aws_s3_bucket_public_access_block" "products" {
  bucket = aws_s3_bucket.products.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "products" {
  bucket = aws_s3_bucket.products.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Product-Detail Remote bucket
resource "aws_s3_bucket" "product_detail" {
  bucket = "${var.project_name}-product-detail-${var.environment}"
}

resource "aws_s3_bucket_public_access_block" "product_detail" {
  bucket = aws_s3_bucket.product_detail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "product_detail" {
  bucket = aws_s3_bucket.product_detail.id
  versioning_configuration {
    status = "Enabled"
  }
}

# =============================================================================
# CloudFront Origin Access Control
# =============================================================================

resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${var.project_name}-oac"
  description                       = "OAC for ${var.project_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# =============================================================================
# S3 Bucket Policies (Allow CloudFront Access)
# =============================================================================

resource "aws_s3_bucket_policy" "shell" {
  bucket = aws_s3_bucket.shell.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.shell.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "products" {
  bucket = aws_s3_bucket.products.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.products.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "product_detail" {
  bucket = aws_s3_bucket.product_detail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.product_detail.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
          }
        }
      }
    ]
  })
}

# =============================================================================
# ACM Certificate
# =============================================================================

resource "aws_acm_certificate" "main" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "main" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# =============================================================================
# CloudFront Distribution
# =============================================================================

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name]
  price_class         = "PriceClass_100" # US, Canada, Europe only (cheapest)

  # Shell (Host) - Default Origin
  origin {
    domain_name              = aws_s3_bucket.shell.bucket_regional_domain_name
    origin_id                = "shell"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }

  # Products Remote Origin
  origin {
    domain_name              = aws_s3_bucket.products.bucket_regional_domain_name
    origin_id                = "products"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }

  # Product-Detail Remote Origin
  origin {
    domain_name              = aws_s3_bucket.product_detail.bucket_regional_domain_name
    origin_id                = "product-detail"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }

  # Default behavior - Shell (Host)
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "shell"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Products Remote behavior
  ordered_cache_behavior {
    path_pattern           = "/remotes/products/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "products"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Product-Detail Remote behavior
  ordered_cache_behavior {
    path_pattern           = "/remotes/product-detail/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "product-detail"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Custom error response for SPA routing
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.main.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  depends_on = [aws_acm_certificate_validation.main]
}

# =============================================================================
# Route53 DNS Record
# =============================================================================

resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

# =============================================================================
# Outputs
# =============================================================================

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "website_url" {
  description = "Website URL"
  value       = "https://${var.domain_name}"
}

output "s3_bucket_shell" {
  description = "S3 bucket for shell app"
  value       = aws_s3_bucket.shell.bucket
}

output "s3_bucket_products" {
  description = "S3 bucket for products remote"
  value       = aws_s3_bucket.products.bucket
}

output "s3_bucket_product_detail" {
  description = "S3 bucket for product-detail remote"
  value       = aws_s3_bucket.product_detail.bucket
}
