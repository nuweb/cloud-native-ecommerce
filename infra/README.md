# AWS Infrastructure Deployment Guide

This guide explains how to deploy the Cloud-Native E-Commerce application to AWS.

## Architecture Overview

```
                    ┌─────────────────────────────────────┐
                    │         Route 53 DNS                │
                    │   ecommerce.veeracs.info           │
                    │   api.veeracs.info                 │
                    └───────────────┬─────────────────────┘
                                    │
                    ┌───────────────┴─────────────────────┐
                    │       CloudFront Distribution       │
                    │   (SSL via ACM Certificate)         │
                    └───────────────┬─────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼
┌───────────────┐         ┌───────────────┐         ┌───────────────┐
│  S3: Shell    │         │ S3: Products  │         │ S3: Detail    │
│  (Host App)   │         │  (Remote)     │         │  (Remote)     │
│  /            │         │ /remotes/     │         │ /remotes/     │
│               │         │  products/*   │         │ product-      │
└───────────────┘         └───────────────┘         │  detail/*     │
                                                    └───────────────┘
                                    │
                    ┌───────────────┴─────────────────────┐
                    │         AWS App Runner               │
                    │   (API Backend - Express.js)         │
                    │   api.veeracs.info                   │
                    └─────────────────────────────────────┘
```

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
3. **Terraform** >= 1.0 installed
4. **Domain** registered and hosted zone in Route 53

### Required AWS Permissions

Your AWS user/role needs permissions for:
- S3 (bucket management)
- CloudFront (distribution management)
- ACM (certificate management)
- Route 53 (DNS management)
- App Runner (service management)
- ECR (container registry)
- IAM (role management)

## Initial Setup

### 1. Configure AWS CLI

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter default region: us-east-1
# Enter output format: json
```

### 2. Verify Route 53 Hosted Zone

Ensure your domain has a hosted zone in Route 53:

```bash
aws route53 list-hosted-zones --query "HostedZones[?Name=='veeracs.info.']"
```

If no hosted zone exists, create one:

```bash
aws route53 create-hosted-zone --name veeracs.info --caller-reference $(date +%s)
```

Then update your domain registrar's nameservers to point to Route 53.

### 3. Initialize Terraform

```bash
cd infra

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the infrastructure
terraform apply
```

## Infrastructure Components

### S3 Buckets

| Bucket | Purpose | Path Pattern |
|--------|---------|--------------|
| `cloud-native-ecommerce-shell-production` | Shell (Host) app | `/` |
| `cloud-native-ecommerce-products-production` | Products remote | `/remotes/products/*` |
| `cloud-native-ecommerce-product-detail-production` | Product Detail remote | `/remotes/product-detail/*` |

### CloudFront Distribution

- **SSL Certificate**: ACM certificate for `ecommerce.veeracs.info`
- **Price Class**: PriceClass_100 (US, Canada, Europe) for cost efficiency
- **Custom Error Response**: 404/403 → index.html (SPA routing)

### App Runner

- **CPU**: 0.25 vCPU
- **Memory**: 512 MB
- **Auto Scaling**: Managed by App Runner
- **Health Check**: HTTP `/api/products`

## Deployment

### Automatic Deployment (GitHub Actions)

Push to `main` branch triggers automatic deployment:

```bash
git push origin main
```

### Manual Deployment

#### Frontend

```bash
# Build all frontend apps
npx nx run-many -t build --configuration=production

# Deploy to S3
aws s3 sync dist/apps/shell s3://cloud-native-ecommerce-shell-production --delete
aws s3 sync dist/apps/products s3://cloud-native-ecommerce-products-production --delete
aws s3 sync dist/apps/product-detail s3://cloud-native-ecommerce-product-detail-production --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

#### API

```bash
# Build and push Docker image
docker build -t cloud-native-ecommerce-api -f apps/api/Dockerfile .

# Tag and push to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

docker tag cloud-native-ecommerce-api:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cloud-native-ecommerce-api:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cloud-native-ecommerce-api:latest
```

## GitHub Actions Secrets

Add these secrets to your GitHub repository:

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key for deployment |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for deployment |
| `NX_CLOUD_ACCESS_TOKEN` | (Optional) Nx Cloud token for caching |

To add secrets:
1. Go to repository Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add each secret

## Cost Estimation

| Service | Estimated Monthly Cost |
|---------|----------------------|
| S3 (3 buckets) | ~$1-5 |
| CloudFront | ~$5-20 (depends on traffic) |
| Route 53 | ~$0.50 (hosted zone) |
| ACM Certificate | Free |
| App Runner | ~$5-25 (depends on usage) |
| ECR | ~$1 (storage) |
| **Total** | **~$15-50/month** |

## Troubleshooting

### Certificate Validation Failed

```bash
# Check certificate status
aws acm describe-certificate \
  --certificate-arn YOUR_CERT_ARN \
  --region us-east-1

# Verify DNS records exist
aws route53 list-resource-record-sets \
  --hosted-zone-id YOUR_ZONE_ID \
  --query "ResourceRecordSets[?Type=='CNAME']"
```

### CloudFront 403 Errors

- Verify S3 bucket policy allows CloudFront OAC access
- Check that files exist in S3 bucket
- Ensure CloudFront is pointing to correct S3 origin

### API Connection Issues

```bash
# Check App Runner service status
aws apprunner describe-service --service-arn YOUR_SERVICE_ARN

# View App Runner logs
aws logs describe-log-groups --log-group-name-prefix /aws/apprunner
```

## Cleanup

To destroy all resources:

```bash
cd infra
terraform destroy
```

**Warning**: This will delete all S3 bucket contents and cannot be undone.

## URLs

After deployment:

| Service | URL |
|---------|-----|
| Website | https://ecommerce.veeracs.info |
| API | https://api.veeracs.info |
