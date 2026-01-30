# Cloud Native E-commerce Deployment Guide

A comprehensive guide to deploying an Nx Module Federation React application to AWS with Terraform and GitHub Actions.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Step 1: AWS Account Setup](#step-1-aws-account-setup)
- [Step 2: Domain Setup](#step-2-domain-setup)
- [Step 3: GitHub Repository Setup](#step-3-github-repository-setup)
- [Step 4: Terraform Infrastructure](#step-4-terraform-infrastructure)
- [Step 5: Application Configuration](#step-5-application-configuration)
- [Step 6: Deployment](#step-6-deployment)
- [Troubleshooting](#troubleshooting)
- [Key Learnings](#key-learnings)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         CloudFront CDN                          │
│                    (ecommerce.veeracs.info)                     │
├─────────────────────────────────────────────────────────────────┤
│    /              │  /remotes/products/*  │ /remotes/product-*  │
│    ↓              │         ↓             │         ↓           │
│  S3: Shell        │    S3: Products       │  S3: Product-Detail │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      AWS App Runner                             │
│              (API - vpw7ds8tch.us-east-1.awsapprunner.com)     │
│                            ↑                                    │
│                     ECR Docker Image                            │
└─────────────────────────────────────────────────────────────────┘
```

**Components:**
- **CloudFront**: CDN for frontend assets with SSL
- **S3 Buckets**: Static hosting for shell and remote modules
- **App Runner**: Managed container service for Node.js API
- **ECR**: Docker image registry
- **Route 53**: DNS management
- **ACM**: SSL certificate management

---

## Prerequisites

### Tools Required

```bash
# Install Homebrew (macOS)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install terraform
brew install awscli
brew install gh

# Verify installations
terraform --version  # v1.5+
aws --version        # v2+
gh --version
```

### AWS CLI Configuration

```bash
# Configure AWS CLI with your credentials
aws configure
# Enter: AWS Access Key ID, Secret Access Key, Region (us-east-1), Output format (json)
```

---

## Step 1: AWS Account Setup

### 1.1 Create IAM User for Deployments

1. Go to AWS Console → IAM → Users → Create User
2. User name: `github-actions-deployer`
3. Attach policies:
   - `AmazonS3FullAccess`
   - `CloudFrontFullAccess`
   - `AmazonEC2ContainerRegistryFullAccess`
   - `AWSAppRunnerFullAccess`
   - `AmazonRoute53FullAccess`
   - `AWSCertificateManagerFullAccess`
   - `IAMFullAccess` (for App Runner role creation)

4. Create Access Key:
   - Security credentials → Create access key
   - Choose "Application running outside AWS"
   - Save the Access Key ID and Secret Access Key

### 1.2 Verify Access

```bash
aws sts get-caller-identity
# Should return your account ID and user ARN
```

---

## Step 2: Domain Setup

### 2.1 Register Domain (if needed)

```bash
# Check if domain is available
aws route53domains check-domain-availability --domain-name yourdomain.info

# Register via AWS Console: Route 53 → Registered domains → Register domain
```

### 2.2 Verify Hosted Zone

```bash
# List hosted zones
aws route53 list-hosted-zones --query "HostedZones[?Name=='yourdomain.info.']"

# Note the Zone ID (e.g., Z05706281FAK5KTGTYUDT)
```

### 2.3 Verify Nameservers

```bash
# Check nameservers are configured
dig yourdomain.info NS +short

# Should return AWS nameservers like:
# ns-xxx.awsdns-xx.org
# ns-xxx.awsdns-xx.co.uk
# ns-xxx.awsdns-xx.com
# ns-xxx.awsdns-xx.net
```

---

## Step 3: GitHub Repository Setup

### 3.1 Create Repository

```bash
# Initialize git (if not already)
git init

# Add remote
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Push code
git push -u origin main
```

### 3.2 Add GitHub Secrets

Go to: Repository → Settings → Secrets and variables → Actions → New repository secret

Add these secrets:
| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Your IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | Your IAM user secret key |

---

## Step 4: Terraform Infrastructure

### 4.1 Create Infrastructure Files

Create `infra/` directory with these files:

**infra/variables.tf**
```hcl
variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  default     = "cloud-native-ecommerce"
}

variable "environment" {
  description = "Environment name"
  default     = "production"
}

variable "domain_name" {
  description = "Domain name for the website"
  default     = "ecommerce.yourdomain.info"
}

variable "root_domain" {
  description = "Root domain"
  default     = "yourdomain.info"
}
```

**infra/main.tf** - See project's `infra/main.tf` for full configuration including:
- S3 buckets for shell, products, product-detail
- CloudFront distribution with cache behaviors
- ACM certificate with DNS validation
- Route 53 records

**infra/api.tf** - See project's `infra/api.tf` for:
- ECR repository
- App Runner service
- IAM roles

### 4.2 Initialize and Apply Terraform

```bash
cd infra

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply (creates all resources)
terraform apply -auto-approve
```

**Important**: CloudFront creation takes 5-15 minutes. App Runner takes 3-5 minutes.

### 4.3 Terraform Output

After successful apply, you'll see:
```
Outputs:
api_service_url = "https://xxxxx.us-east-1.awsapprunner.com"
cloudfront_distribution_id = "EXXXXXXXXXX"
website_url = "https://ecommerce.yourdomain.info"
```

---

## Step 5: Application Configuration

### 5.1 API Configuration

**Critical**: The API must bind to `0.0.0.0`, not `localhost`:

```typescript
// apps/api/src/main.ts
const host = process.env.HOST ?? '0.0.0.0';  // NOT 'localhost'
const port = process.env.PORT ? Number(process.env.PORT) : 3333;

app.listen(port, host, () => {
  console.log(`[ ready ] http://${host}:${port}`);
});
```

**Why**: App Runner health checks come from outside the container. `localhost` only listens on loopback interface.

### 5.2 Frontend API URL Configuration

```typescript
// libs/shop/data/src/lib/config.ts
const getApiUrl = (): string => {
  if (typeof window !== 'undefined') {
    const hostname = window.location.hostname;
    if (hostname !== 'localhost' && hostname !== '127.0.0.1') {
      // Use App Runner URL directly (has valid SSL)
      return 'https://YOUR_APPRUNNER_URL.us-east-1.awsapprunner.com/api';
    }
  }
  return 'http://localhost:3333/api';
};
```

### 5.3 Module Federation Configuration

```typescript
// apps/shell/webpack.config.ts
import { composePlugins, withNx } from '@nx/webpack';
import { withReact } from '@nx/react';
import { withModuleFederation } from '@nx/module-federation/webpack';
import { ModuleFederationConfig, Remotes } from '@nx/module-federation';

const isProd = process.env['NODE_ENV'] === 'production';
const PROD_DOMAIN = process.env['PROD_DOMAIN'] || 'https://ecommerce.yourdomain.info';

// Use tuple format: [remoteName, remoteUrl]
const prodRemotes: Remotes = [
  ['products', `${PROD_DOMAIN}/remotes/products/remoteEntry.js`],
  ['product-detail', `${PROD_DOMAIN}/remotes/product-detail/remoteEntry.js`],
];

const devRemotes: Remotes = [
  ['products', 'http://localhost:4201/remoteEntry.js'],
  ['product-detail', 'http://localhost:4202/remoteEntry.js'],
];

const config: ModuleFederationConfig = {
  name: 'shell',
  remotes: isProd ? prodRemotes : devRemotes,
};

export default composePlugins(
  withNx(),
  withReact(),
  withModuleFederation(config, { dts: false })
);
```

### 5.4 Dockerfile

```dockerfile
# apps/api/Dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
RUN npm install -g pnpm
COPY package.json pnpm-workspace.yaml ./
COPY pnpm-lock.yaml* ./
COPY apps/api/package.json ./apps/api/
COPY libs/api/products/package.json ./libs/api/products/
COPY libs/shared/models/package.json ./libs/shared/models/
RUN pnpm install
COPY . .
RUN npx nx build api --configuration=production --skip-nx-cache

FROM node:20-alpine AS runner
WORKDIR /app
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 api
COPY --from=builder /app/apps/api/dist/main.js ./main.js
COPY --from=builder /app/node_modules ./node_modules
RUN chown -R api:nodejs /app
USER api
EXPOSE 3333
CMD ["node", "main.js"]
```

---

## Step 6: Deployment

### 6.1 GitHub Actions Workflow

Create `.github/workflows/deploy.yml` - see project file for full configuration.

Key points:
- Build frontend apps with `NODE_ENV=production`
- Upload to S3 with correct paths:
  - Shell → `s3://bucket-shell/`
  - Products → `s3://bucket-products/remotes/products/`
  - Product-Detail → `s3://bucket-product-detail/remotes/product-detail/`
- Build and push Docker image to ECR
- Invalidate CloudFront cache

### 6.2 Trigger Deployment

```bash
# Commit and push changes
git add -A
git commit -m "Deploy to AWS"
git push origin main

# GitHub Actions will automatically:
# 1. Build frontend apps
# 2. Upload to S3
# 3. Build Docker image
# 4. Push to ECR
# 5. App Runner auto-deploys new image
# 6. Invalidate CloudFront cache
```

### 6.3 Monitor Deployment

```bash
# Check GitHub Actions
# Go to: Repository → Actions → Latest workflow run

# Check App Runner status
aws apprunner list-services --query "ServiceSummaryList[*].{Name:ServiceName,Status:Status,URL:ServiceUrl}"

# Check CloudFront status
aws cloudfront get-distribution --id YOUR_DISTRIBUTION_ID --query "Distribution.Status"
```

---

## Troubleshooting

### Issue 1: App Runner Health Check Fails

**Symptoms**: App Runner stuck in `OPERATION_IN_PROGRESS` for 20 minutes, then fails.

**Cause**: API binding to `localhost` instead of `0.0.0.0`.

**Fix**:
```typescript
// apps/api/src/main.ts
const host = process.env.HOST ?? '0.0.0.0';  // Changed from 'localhost'
```

**Verify**:
```bash
# Check App Runner logs
aws logs get-log-events \
  --log-group-name "/aws/apprunner/SERVICE_NAME/SERVICE_ID/application" \
  --log-stream-name "$(aws logs describe-log-streams ...)" \
  --query "events[*].message"

# Should show: [ ready ] http://0.0.0.0:3333
```

### Issue 2: Module Federation remoteEntry.js Returns HTML

**Symptoms**: Console error "Expected JavaScript but got text/html"

**Cause**: Files uploaded to wrong S3 path.

**Fix**: Upload with correct path prefix:
```yaml
# .github/workflows/deploy.yml
- name: Deploy Products to S3
  run: |
    aws s3 sync dist/products s3://bucket-products/remotes/products \
      --delete
```

### Issue 3: SSL Certificate for Custom API Domain

**Symptoms**: "Your connection is not private" for api.yourdomain.info

**Cause**: App Runner's SSL only covers `*.awsapprunner.com`.

**Quick Fix**: Use App Runner URL directly in frontend config.

**Proper Fix**: Use App Runner Custom Domains feature (adds automatic SSL).

### Issue 4: Terraform State Lock

**Symptoms**: "Error acquiring the state lock"

**Fix**:
```bash
# Remove stale lock file
rm -f infra/.terraform.tfstate.lock.info

# Or force unlock
terraform force-unlock LOCK_ID

# Or bypass lock (use carefully)
terraform apply -lock=false
```

### Issue 5: App Runner Service Already Exists

**Symptoms**: Terraform error "Service with provided name already exists"

**Fix**:
```bash
# Delete existing service
SERVICE_ARN=$(aws apprunner list-services --query "ServiceSummaryList[?ServiceName=='SERVICE_NAME'].ServiceArn" --output text)
aws apprunner delete-service --service-arn "$SERVICE_ARN"

# Wait for deletion
sleep 60

# Re-run Terraform
terraform apply
```

### Issue 6: CloudFront CNAME Already Exists

**Symptoms**: Terraform error "CNAMEAlreadyExists"

**Fix**:
```bash
# Find and delete existing distribution
DIST_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?Aliases.Items[?@=='yourdomain.info']].Id" --output text)

# Disable distribution first
aws cloudfront get-distribution-config --id $DIST_ID > config.json
# Edit config.json: set Enabled=false
aws cloudfront update-distribution --id $DIST_ID --if-match ETAG --distribution-config file://config.json

# Wait for deployment, then delete
aws cloudfront delete-distribution --id $DIST_ID --if-match NEW_ETAG
```

---

## Key Learnings

1. **API Host Binding**: Always use `0.0.0.0` in containerized apps for external access.

2. **Module Federation Paths**: CloudFront passes full request path to S3. Files must be at matching paths.

3. **App Runner Health Checks**: Use simple endpoints (`/` or `/health`) that respond quickly.

4. **SSL with Custom Domains**: App Runner CNAME alone doesn't provide SSL. Use App Runner Custom Domains or CloudFront for proper SSL.

5. **Terraform State**: Local state files can get locked. Keep backups and know how to unlock.

6. **DNS Propagation**: Route 53 changes are usually fast, but can take up to 48 hours globally.

7. **ECR Image Tags**: App Runner auto-deploys when `latest` tag is updated.

---

## Useful Commands Reference

```bash
# === AWS App Runner ===
aws apprunner list-services
aws apprunner describe-service --service-arn ARN
aws apprunner delete-service --service-arn ARN

# === CloudFront ===
aws cloudfront list-distributions
aws cloudfront create-invalidation --distribution-id ID --paths "/*"

# === S3 ===
aws s3 ls s3://bucket-name/
aws s3 sync ./dist s3://bucket-name/ --delete

# === ECR ===
aws ecr describe-images --repository-name REPO_NAME
aws ecr get-login-password | docker login --username AWS --password-stdin ACCOUNT.dkr.ecr.REGION.amazonaws.com

# === Route 53 ===
aws route53 list-hosted-zones
aws route53 list-resource-record-sets --hosted-zone-id ZONE_ID

# === Terraform ===
terraform init
terraform plan
terraform apply -auto-approve
terraform apply -auto-approve -lock=false
terraform destroy
terraform force-unlock LOCK_ID
```

---

## Cost Estimation (Monthly)

| Service | Estimated Cost |
|---------|---------------|
| Route 53 Hosted Zone | $0.50 |
| CloudFront | $0 - $10 (depends on traffic) |
| S3 | $0 - $5 (depends on storage) |
| ACM Certificate | Free |
| App Runner (0.25 vCPU, 0.5GB) | ~$5-15 |
| ECR | $0 - $1 |
| **Total** | **~$6-30/month** |

---

## Next Steps

- [ ] Set up App Runner Custom Domains for proper SSL on api.yourdomain.info
- [ ] Add staging environment
- [ ] Set up monitoring with CloudWatch
- [ ] Configure CloudFront caching policies
- [ ] Add WAF for security
- [ ] Set up CI/CD for multiple branches
