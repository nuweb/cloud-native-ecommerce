# =============================================================================
# API Infrastructure - AWS App Runner
# =============================================================================

# =============================================================================
# ECR Repository for API Docker Image
# =============================================================================

resource "aws_ecr_repository" "api" {
  name                 = "${var.project_name}-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# =============================================================================
# App Runner Service
# =============================================================================

resource "aws_apprunner_service" "api" {
  service_name = "${var.project_name}-api"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_access.arn
    }

    image_repository {
      image_configuration {
        port = "3333"
        runtime_environment_variables = {
          NODE_ENV = "production"
          CORS_ORIGIN = "https://${var.domain_name}"
        }
      }
      image_identifier      = "${aws_ecr_repository.api.repository_url}:latest"
      image_repository_type = "ECR"
    }

    auto_deployments_enabled = true
  }

  instance_configuration {
    cpu    = "256"   # 0.25 vCPU
    memory = "512"   # 0.5 GB
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = "/api/products"
    healthy_threshold   = 1
    unhealthy_threshold = 5
    interval            = 10
  }
}

# =============================================================================
# IAM Role for App Runner ECR Access
# =============================================================================

resource "aws_iam_role" "apprunner_ecr_access" {
  name = "${var.project_name}-apprunner-ecr-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr_access" {
  role       = aws_iam_role.apprunner_ecr_access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# =============================================================================
# Custom Domain for API
# Note: Custom domain setup for App Runner requires manual DNS validation
# after the service is created. The service URL will be used initially.
# =============================================================================

# Route53 CNAME record pointing to App Runner service
resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "api.${var.root_domain}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_apprunner_service.api.service_url]
}

# =============================================================================
# Outputs
# =============================================================================

output "api_service_url" {
  description = "App Runner service URL"
  value       = "https://${aws_apprunner_service.api.service_url}"
}

output "api_custom_domain" {
  description = "API custom domain"
  value       = "https://api.${var.root_domain}"
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.api.repository_url
}
