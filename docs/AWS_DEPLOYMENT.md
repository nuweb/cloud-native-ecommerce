# AWS Deployment Guide

Complete guide for deploying the Cloud-Native E-Commerce application to AWS.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Files Created for Deployment](#files-created-for-deployment)
- [Prerequisites](#prerequisites)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [GitHub Actions CI/CD](#github-actions-cicd)
- [Manual Deployment](#manual-deployment)
- [Cost Estimation](#cost-estimation)
- [Troubleshooting](#troubleshooting)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                        │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │       Route 53 DNS        │
                    │  ecommerce.veeracs.info   │
                    │  api.veeracs.info         │
                    └─────────────┬─────────────┘
                                  │
            ┌─────────────────────┴─────────────────────┐
            │                                           │
            ▼                                           ▼
┌───────────────────────────────────────┐   ┌─────────────────────────┐
│        CloudFront Distribution        │   │     AWS App Runner      │
│   (CDN + SSL via ACM Certificate)     │   │    (API Container)      │
│                                       │   │                         │
│   ecommerce.veeracs.info              │   │   api.veeracs.info      │
└───────────────┬───────────────────────┘   └─────────────────────────┘
                │
    ┌───────────┼───────────┬───────────────────┐
    │           │           │                   │
    ▼           ▼           ▼                   │
┌───────┐   ┌───────┐   ┌───────────┐          │
│  S3   │   │  S3   │   │    S3     │          │
│ Shell │   │Product│   │ Product   │          │
│(Host) │   │  List │   │  Detail   │          │
│  /    │   │Remote │   │  Remote   │          │
└───────┘   └───────┘   └───────────┘          │
                                               │
                              ┌─────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │   Amazon ECR        │
                    │ (Docker Registry)   │
                    └─────────────────────┘
```

### Service Overview

| Service                 | Domain                     | Purpose                                   |
| ----------------------- | -------------------------- | ----------------------------------------- |
| **CloudFront**          | ecommerce.veeracs.info     | CDN for frontend apps                     |
| **S3 (Shell)**          | /\*                        | Host application (Module Federation host) |
| **S3 (Products)**       | /remotes/products/\*       | Products microfrontend                    |
| **S3 (Product Detail)** | /remotes/product-detail/\* | Product detail microfrontend              |
| **App Runner**          | api.veeracs.info           | Express.js API backend                    |
| **ECR**                 | -                          | Docker image registry                     |
| **ACM**                 | -                          | SSL/TLS certificates                      |
| **Route 53**            | -                          | DNS management                            |

---

## Files Created for Deployment

### Infrastructure (Terraform)

| File               | Description                      |
| ------------------ | -------------------------------- |
| `infra/main.tf`    | Main Terraform configuration     |
| `infra/api.tf`     | App Runner and ECR configuration |
| `infra/.gitignore` | Ignores Terraform state files    |
| `infra/README.md`  | Infrastructure documentation     |

#### `infra/main.tf` - Contains:

- S3 buckets for Shell, Products, and Product-Detail
- S3 bucket policies for CloudFront access
- CloudFront Origin Access Control (OAC)
- CloudFront Distribution with multiple origins
- ACM SSL certificate with DNS validation
- Route 53 DNS records

#### `infra/api.tf` - Contains:

- ECR repository for API Docker images
- App Runner service configuration
- IAM roles for App Runner ECR access
- Custom domain configuration for API

### CI/CD Pipeline

| File                           | Description                        |
| ------------------------------ | ---------------------------------- |
| `.github/workflows/deploy.yml` | GitHub Actions deployment workflow |

#### Workflow Jobs:

1. **build-frontend** - Builds Shell, Products, and Product-Detail apps
2. **build-api** - Builds and pushes API Docker image to ECR
3. **deploy-frontend** - Syncs built assets to S3 and invalidates CloudFront
4. **summary** - Outputs deployment status

### Application Configuration

| File                                | Description                                |
| ----------------------------------- | ------------------------------------------ |
| `apps/api/Dockerfile`               | Multi-stage Docker build for API           |
| `apps/shell/webpack.config.prod.ts` | Production webpack config with remote URLs |
| `libs/shop/data/src/lib/config.ts`  | Environment-aware API URL configuration    |

### Modified Files

| File                                           | Changes                              |
| ---------------------------------------------- | ------------------------------------ |
| `apps/shell/module-federation.config.ts`       | Added production remote URLs         |
| `apps/shell/package.json`                      | Added production build configuration |
| `libs/shop/data/src/lib/hooks/use-products.ts` | Uses config for API URL              |
| `libs/shop/data/src/lib/hooks/use-product.ts`  | Uses config for API URL              |
| `README.md`                                    | Added AWS deployment section         |

---

## Prerequisites

### 1. AWS Account Setup

- AWS Account with admin access or appropriate IAM permissions
- AWS CLI installed and configured

```bash
# Install AWS CLI (macOS)
brew install awscli

# Configure credentials
aws configure
```

### 2. Required IAM Permissions

Your AWS user/role needs:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "cloudfront:*",
        "acm:*",
        "route53:*",
        "apprunner:*",
        "ecr:*",
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
```

### 3. Terraform Installation

```bash
# macOS
brew install terraform

# Verify installation
terraform version
```

### 4. Domain Configuration

Ensure your domain (`veeracs.info`) has a hosted zone in Route 53:

```bash
# Check for existing hosted zone
aws route53 list-hosted-zones --query "HostedZones[?Name=='veeracs.info.']"

# Create if not exists
aws route53 create-hosted-zone \
  --name veeracs.info \
  --caller-reference $(date +%s)
```

**Important**: Update your domain registrar's nameservers to point to Route 53.

---

## Step-by-Step Deployment

### Step 1: Initialize Terraform

```bash
cd infra
terraform init
```

### Step 2: Review Infrastructure Plan

```bash
terraform plan
```

Review the output to understand what will be created.

### Step 3: Apply Infrastructure

```bash
terraform apply
```

Type `yes` when prompted. This creates:

- 3 S3 buckets
- 1 CloudFront distribution
- 1 ACM certificate
- DNS records
- ECR repository
- App Runner service

**Note**: Certificate validation may take 5-30 minutes.

### Step 4: Get Output Values

```bash
terraform output
```

Save these values:

- `cloudfront_distribution_id`
- `website_url`
- `api_service_url`
- `ecr_repository_url`

### Step 5: Configure GitHub Secrets

Go to your GitHub repository:

1. Settings → Secrets and variables → Actions
2. Add these secrets:

| Secret Name             | Value                     |
| ----------------------- | ------------------------- |
| `AWS_ACCESS_KEY_ID`     | Your AWS access key       |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key       |
| `NX_CLOUD_ACCESS_TOKEN` | (Optional) Nx Cloud token |

### Step 6: Deploy via Git Push

```bash
git add .
git commit -m "feat: add AWS deployment infrastructure"
git push origin main
```

GitHub Actions will automatically:

1. Build all frontend applications
2. Build and push API Docker image
3. Deploy to S3
4. Invalidate CloudFront cache

### Step 7: Verify Deployment

- **Frontend**: https://ecommerce.veeracs.info
- **API**: https://api.veeracs.info/api/products

---

## GitHub Actions CI/CD

### Workflow Triggers

```yaml
on:
  push:
    branches: [main] # Auto-deploy on push to main
  workflow_dispatch: # Manual trigger
```

### Environment Variables

| Variable      | Value                  |
| ------------- | ---------------------- |
| `AWS_REGION`  | us-east-1              |
| `DOMAIN_NAME` | ecommerce.veeracs.info |
| `API_DOMAIN`  | api.veeracs.info       |

### Build Artifacts

The workflow creates these artifacts (retained for 1 day):

- `shell-dist` - Host application
- `products-dist` - Products remote
- `product-detail-dist` - Product detail remote

### Deployment Process

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Build Frontend │───▶│  Build API      │───▶│ Deploy Frontend │
│  (pnpm + nx)    │    │  (Docker)       │    │  (S3 sync)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                      │
                                                      ▼
                                              ┌─────────────────┐
                                              │ Invalidate CDN  │
                                              │ (CloudFront)    │
                                              └─────────────────┘
```

---

## Manual Deployment

### Frontend Deployment

```bash
# 1. Build applications
npx nx build shell --configuration=production
npx nx build products --configuration=production
npx nx build product-detail --configuration=production

# 2. Deploy to S3
aws s3 sync dist/apps/shell \
  s3://cloud-native-ecommerce-shell-production \
  --delete

aws s3 sync dist/apps/products \
  s3://cloud-native-ecommerce-products-production \
  --delete

aws s3 sync dist/apps/product-detail \
  s3://cloud-native-ecommerce-product-detail-production \
  --delete

# 3. Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

### API Deployment

```bash
# 1. Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# 2. Build Docker image
docker build -t cloud-native-ecommerce-api \
  -f apps/api/Dockerfile .

# 3. Tag image
docker tag cloud-native-ecommerce-api:latest \
  YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cloud-native-ecommerce-api:latest

# 4. Push to ECR
docker push \
  YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cloud-native-ecommerce-api:latest
```

App Runner automatically deploys when a new image is pushed.

---

## Cost Estimation

### Monthly Cost Breakdown

| Service        | Configuration                | Est. Cost        |
| -------------- | ---------------------------- | ---------------- |
| **S3**         | 3 buckets, ~100MB storage    | $0.50-2          |
| **CloudFront** | 10GB transfer, 100k requests | $5-15            |
| **Route 53**   | 1 hosted zone, DNS queries   | $0.50-1          |
| **ACM**        | SSL certificate              | Free             |
| **App Runner** | 0.25 vCPU, 512MB             | $5-25            |
| **ECR**        | ~500MB storage               | $0.50-1          |
| **Total**      | Low traffic                  | **$12-45/month** |

### Cost Optimization Tips

1. **CloudFront Price Class**: Using `PriceClass_100` (US/Europe only) reduces costs
2. **App Runner**: Scales to zero when not in use (pay per request)
3. **S3 Lifecycle**: Add rules to clean up old versions

---

## Troubleshooting

### Certificate Not Validating

```bash
# Check certificate status
aws acm describe-certificate \
  --certificate-arn YOUR_CERT_ARN \
  --region us-east-1 \
  --query "Certificate.Status"

# List validation records
aws acm describe-certificate \
  --certificate-arn YOUR_CERT_ARN \
  --region us-east-1 \
  --query "Certificate.DomainValidationOptions"
```

**Solution**: Ensure CNAME records are created in Route 53.

### CloudFront 403 Forbidden

**Causes**:

- S3 bucket policy missing
- Object doesn't exist
- OAC not configured

```bash
# Verify bucket policy
aws s3api get-bucket-policy \
  --bucket cloud-native-ecommerce-shell-production

# List bucket contents
aws s3 ls s3://cloud-native-ecommerce-shell-production
```

### API Not Responding

```bash
# Check App Runner service status
aws apprunner list-services

# View service logs
aws apprunner describe-service \
  --service-arn YOUR_SERVICE_ARN
```

### Module Federation Errors

If remotes fail to load:

1. Check CloudFront is serving files correctly
2. Verify remote URLs in production config
3. Check browser console for CORS errors

```bash
# Test remote entry
curl https://ecommerce.veeracs.info/remotes/products/remoteEntry.js
```

### GitHub Actions Failing

1. Check AWS credentials are correctly set as secrets
2. Verify S3 bucket names match Terraform outputs
3. Check ECR repository exists

---

## Cleanup

To destroy all AWS resources:

```bash
cd infra

# Remove all resources
terraform destroy
```

**Warning**: This deletes all data including S3 bucket contents.

---

## Quick Reference

### URLs

| Environment     | Frontend                       | API                      |
| --------------- | ------------------------------ | ------------------------ |
| **Production**  | https://ecommerce.veeracs.info | https://api.veeracs.info |
| **Development** | http://localhost:4200          | http://localhost:3333    |

### Useful Commands

```bash
# View Terraform state
terraform show

# Update single resource
terraform apply -target=aws_s3_bucket.shell

# View CloudFront distribution
aws cloudfront get-distribution --id YOUR_DIST_ID

# Tail App Runner logs
aws logs tail /aws/apprunner/cloud-native-ecommerce-api --follow
```

### Key Files

```
cloud-native-ecommerce/
├── infra/
│   ├── main.tf              # S3, CloudFront, ACM, Route53
│   ├── api.tf               # App Runner, ECR
│   └── README.md            # Infrastructure docs
├── .github/workflows/
│   └── deploy.yml           # CI/CD pipeline
├── apps/api/
│   └── Dockerfile           # API container
└── AWS_DEPLOYMENT.md        # This file
```
