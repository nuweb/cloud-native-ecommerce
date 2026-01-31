# System Design Document

## Cloud-Native E-Commerce Platform

**Version:** 1.0  
**Last Updated:** January 2026  
**Status:** Production

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [System Architecture Overview](#2-system-architecture-overview)
3. [Component Architecture](#3-component-architecture)
4. [Data Flow](#4-data-flow)
5. [Infrastructure Architecture](#5-infrastructure-architecture)
6. [Technology Stack](#6-technology-stack)
7. [Deployment Architecture](#7-deployment-architecture)
8. [Security Architecture](#8-security-architecture)
9. [Scalability & Performance](#9-scalability--performance)
10. [Reliability & Fault Tolerance](#10-reliability--fault-tolerance)
11. [Monitoring & Observability](#11-monitoring--observability)
12. [Cost Analysis](#12-cost-analysis)
13. [Future Considerations](#13-future-considerations)

---

## 1. Executive Summary

### 1.1 Purpose

This document describes the system design for the Cloud-Native E-Commerce Platform, a production-ready microfrontend application built using modern cloud-native principles. The platform demonstrates enterprise-grade architecture patterns suitable for large-scale e-commerce operations.

### 1.2 Goals

| Goal | Description |
|------|-------------|
| **Scalability** | Handle traffic spikes without manual intervention |
| **Independent Deployability** | Deploy frontend modules independently |
| **Team Autonomy** | Enable multiple teams to work in parallel |
| **Performance** | Sub-second page loads globally |
| **Reliability** | 99.9% uptime target |
| **Cost Efficiency** | Pay-per-use cloud infrastructure |

### 1.3 Key Features

- **Product Catalog** - Browse products with search, filtering, and pagination
- **Product Details** - Detailed product pages with images and specifications
- **Responsive Design** - Mobile-first UI across all device sizes
- **API Backend** - RESTful API serving product data

### 1.4 Architecture Summary

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           USERS (Web Browsers)                               │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │         AWS CloudFront CDN        │
                    │   (Global Edge, SSL Termination)  │
                    └─────────────────┬─────────────────┘
                                      │
          ┌───────────────────────────┼───────────────────────────┐
          │                           │                           │
          ▼                           ▼                           ▼
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│   S3: Shell     │       │  S3: Products   │       │ S3: Product     │
│   (MFE Host)    │       │  (MFE Remote)   │       │ Detail (Remote) │
└─────────────────┘       └─────────────────┘       └─────────────────┘
          │                                                   │
          └───────────────────────┬───────────────────────────┘
                                  │ API Calls
                                  ▼
                    ┌─────────────────────────────┐
                    │     AWS App Runner          │
                    │     (Express.js API)        │
                    └─────────────────────────────┘
```

---

## 2. System Architecture Overview

### 2.1 High-Level Architecture

The platform follows a **Microfrontend Architecture** pattern using Webpack Module Federation, deployed on AWS cloud infrastructure.

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                    INTERNET                                      │
└─────────────────────────────────────┬───────────────────────────────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │       Route 53 DNS                 │
                    │  ecommerce.veeracs.info           │
                    │  api.veeracs.info                 │
                    └─────────────────┬─────────────────┘
                                      │
            ┌─────────────────────────┴─────────────────────────┐
            │                                                   │
            ▼                                                   ▼
┌───────────────────────────────────────┐       ┌─────────────────────────┐
│        CloudFront Distribution        │       │     AWS App Runner      │
│   (CDN + SSL via ACM Certificate)     │       │    (API Container)      │
│                                       │       │                         │
│   ecommerce.veeracs.info              │       │   api.veeracs.info      │
└───────────────┬───────────────────────┘       └────────────┬────────────┘
                │                                            │
    ┌───────────┼───────────┬───────────────────┐           │
    │           │           │                   │           │
    ▼           ▼           ▼                   │           │
┌───────┐   ┌───────┐   ┌───────────┐          │           │
│  S3   │   │  S3   │   │    S3     │          │           │
│ Shell │   │Product│   │ Product   │          │           │
│(Host) │   │  List │   │  Detail   │          │           │
│  /    │   │Remote │   │  Remote   │          │           │
└───────┘   └───────┘   └───────────┘          │           │
                                               │           │
                              ┌────────────────┘           │
                              │                            │
                              ▼                            │
                    ┌─────────────────────┐                │
                    │   Amazon ECR        │◄───────────────┘
                    │ (Docker Registry)   │
                    └─────────────────────┘
```

### 2.2 Architecture Principles

| Principle | Implementation |
|-----------|----------------|
| **Separation of Concerns** | Distinct microfrontends for product listing and details |
| **Loose Coupling** | Module Federation enables runtime integration |
| **High Cohesion** | Feature libraries encapsulate related functionality |
| **Single Responsibility** | Each library has one clear purpose |
| **DRY (Don't Repeat Yourself)** | Shared UI components and utilities |
| **Infrastructure as Code** | Terraform manages all AWS resources |

### 2.3 Architectural Patterns

| Pattern | Usage |
|---------|-------|
| **Microfrontend** | Independent frontend modules loaded at runtime |
| **Monorepo** | Single repository for all applications and libraries |
| **Module Federation** | Webpack 5 feature for runtime module sharing |
| **Backend for Frontend (BFF)** | Express.js API tailored for frontend needs |
| **CDN-First** | CloudFront serves all static assets globally |
| **Containerization** | Docker for API deployment portability |

---

## 3. Component Architecture

### 3.1 Frontend Architecture

#### 3.1.1 Module Federation Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                    Shell (Host) - Port 4200                      │
│                                                                  │
│   Loads remotes at runtime via remoteEntry.js                   │
│                                                                  │
│   ┌─────────────────────┐    ┌─────────────────────────────────┐│
│   │  Products Remote    │    │  Product-Detail Remote          ││
│   │  (Port 4201)        │    │  (Port 4202)                    ││
│   │                     │    │                                 ││
│   │  /products          │    │  /products/:id                  ││
│   └─────────────────────┘    └─────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

#### 3.1.2 Application Components

| Application | Type | Description | Port | Build Tool |
|-------------|------|-------------|------|------------|
| **shell** | MFE Host | Main entry point, routing, layout | 4200 | Webpack |
| **products** | MFE Remote | Product listing page | 4201 | Webpack |
| **product-detail** | MFE Remote | Product detail page | 4202 | Webpack |
| **shop** | Standalone | Alternative monolithic app | 4200 | Vite |
| **api** | Backend | REST API server | 3333 | esbuild |

#### 3.1.3 Library Architecture

```
libs/
├── shop/                        # Frontend domain
│   ├── feature-products/        # Product list smart component
│   │   └── ProductList          # Filtering, pagination, display
│   ├── feature-product-detail/  # Product detail smart component
│   │   └── ProductDetail        # Single product view
│   ├── data/                    # Data access layer
│   │   ├── useProducts()        # Products list hook
│   │   ├── useProduct()         # Single product hook
│   │   └── useCategories()      # Categories hook
│   └── shared-ui/               # Presentational components
│       ├── ProductCard          # Product card display
│       ├── ProductGrid          # Grid layout
│       ├── LoadingSpinner       # Loading state
│       └── ErrorMessage         # Error display
│
├── api/                         # Backend domain
│   └── products/                # Products service
│       └── ProductsService      # CRUD operations
│
└── shared/                      # Cross-cutting concerns
    ├── models/                  # TypeScript interfaces
    │   ├── Product              # Product type
    │   ├── ApiResponse<T>       # API response wrapper
    │   └── ProductFilter        # Filter criteria
    └── test-utils/              # Testing utilities
        └── mock-data            # Mock products
```

#### 3.1.4 Library Dependencies

```
                    ┌─────────────────┐
                    │     shell       │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
    ┌─────────────────┐ ┌─────────────────┐
    │    products     │ │  product-detail │
    └────────┬────────┘ └────────┬────────┘
             │                   │
             └─────────┬─────────┘
                       ▼
              ┌─────────────────┐
              │ feature-products│◄────────┐
              │ feature-detail  │         │
              └────────┬────────┘         │
                       │                  │
         ┌─────────────┼─────────────┐    │
         ▼             ▼             ▼    │
   ┌──────────┐  ┌──────────┐  ┌──────────┤
   │shop-data │  │shared-ui │  │  models  │
   └────┬─────┘  └──────────┘  └──────────┘
        │
        ▼
   ┌──────────┐
   │  models  │
   └──────────┘
```

### 3.2 Backend Architecture

#### 3.2.1 API Structure

```
┌─────────────────────────────────────────────────────────────┐
│                     Express.js Server                        │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    Middleware                        │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │   │
│  │  │  CORS    │  │  JSON    │  │  Error Handler   │  │   │
│  │  └──────────┘  └──────────┘  └──────────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                      Routes                          │   │
│  │                                                      │   │
│  │  GET /api/products          - List with filters      │   │
│  │  GET /api/products/:id      - Single product         │   │
│  │  GET /api/products/categories - All categories       │   │
│  │  GET /health                - Health check           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                  ProductsService                     │   │
│  │                                                      │   │
│  │  - In-memory product storage (12 products)          │   │
│  │  - Filtering (category, price, stock, search)       │   │
│  │  - Pagination                                        │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

#### 3.2.2 API Endpoints

| Endpoint | Method | Description | Query Parameters |
|----------|--------|-------------|------------------|
| `/api/products` | GET | List products | `category`, `minPrice`, `maxPrice`, `inStock`, `search`, `page`, `pageSize` |
| `/api/products/:id` | GET | Get single product | - |
| `/api/products/categories` | GET | List categories | - |
| `/health` | GET | Health check | - |

#### 3.2.3 Data Model

```typescript
interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  imageUrl: string;
  category: string;
  stock: number;
  rating: number;
  reviews: number;
}

interface ProductFilter {
  category?: string;
  minPrice?: number;
  maxPrice?: number;
  inStock?: boolean;
  search?: string;
}

interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}
```

---

## 4. Data Flow

### 4.1 Request Flow - Product Listing

```
┌──────┐     ┌───────────┐     ┌──────────┐     ┌───────────┐     ┌─────────┐
│ User │────▶│ CloudFront│────▶│ S3 Shell │────▶│ Products  │────▶│ API     │
│      │     │           │     │          │     │ Remote    │     │ Server  │
└──────┘     └───────────┘     └──────────┘     └───────────┘     └─────────┘
    │              │                 │                │                │
    │   1. GET /products             │                │                │
    │─────────────▶│                 │                │                │
    │              │  2. Serve Shell │                │                │
    │              │────────────────▶│                │                │
    │              │                 │                │                │
    │   3. index.html + JS           │                │                │
    │◀─────────────────────────────────               │                │
    │                                                 │                │
    │   4. Load remoteEntry.js                        │                │
    │─────────────────────────────────────────────────▶                │
    │                                                 │                │
    │   5. Fetch /api/products                        │                │
    │──────────────────────────────────────────────────────────────────▶
    │                                                 │                │
    │   6. JSON Response                              │                │
    │◀──────────────────────────────────────────────────────────────────
    │                                                 │                │
    │   7. Render Product List                        │                │
    │◀─────────────────────────────────────────────────                │
```

### 4.2 State Management

```
┌─────────────────────────────────────────────────────────────┐
│                    Component State Flow                      │
│                                                             │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐   │
│   │ URL State   │    │ React State │    │ API Data    │   │
│   │ (Router)    │───▶│ (useState)  │◀───│ (Hooks)     │   │
│   └─────────────┘    └─────────────┘    └─────────────┘   │
│          │                   │                   │         │
│          ▼                   ▼                   ▼         │
│   ┌─────────────────────────────────────────────────┐     │
│   │              UI Components                       │     │
│   │                                                  │     │
│   │  ProductList ──▶ ProductGrid ──▶ ProductCard    │     │
│   └─────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### 4.3 Data Hooks

```typescript
// useProducts Hook Flow
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│  useProducts(filter, page, pageSize)                        │
│          │                                                   │
│          ▼                                                   │
│  ┌─────────────────┐                                        │
│  │  useState       │ ← products, loading, error             │
│  └────────┬────────┘                                        │
│           │                                                  │
│           ▼                                                  │
│  ┌─────────────────┐                                        │
│  │   useEffect     │ ← Fetch on filter/page change          │
│  └────────┬────────┘                                        │
│           │                                                  │
│           ▼                                                  │
│  ┌─────────────────┐                                        │
│  │  fetch(API_URL) │ ← GET /api/products?...                │
│  └────────┬────────┘                                        │
│           │                                                  │
│           ▼                                                  │
│  ┌─────────────────┐                                        │
│  │  Update State   │ ← setProducts, setLoading              │
│  └─────────────────┘                                        │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 5. Infrastructure Architecture

### 5.1 AWS Services Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS Cloud Infrastructure                     │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │                      Route 53 (DNS)                         │    │
│  │  - ecommerce.veeracs.info → CloudFront                     │    │
│  │  - api.veeracs.info → App Runner                           │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │                ACM (SSL/TLS Certificates)                   │    │
│  │  - *.veeracs.info (DNS validated)                          │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │           CloudFront Distribution (CDN)                     │    │
│  │  - Origins: S3 buckets (Shell, Products, Product-Detail)   │    │
│  │  - Price Class: US, Canada, Europe                         │    │
│  │  - Custom error responses for SPA routing                  │    │
│  │  - Origin Access Control (OAC) for S3                      │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                     │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐          │
│  │ S3: Shell     │  │ S3: Products  │  │S3: Product    │          │
│  │               │  │               │  │   Detail      │          │
│  │ - index.html  │  │ - remoteEntry │  │ - remoteEntry │          │
│  │ - main.js     │  │ - chunks      │  │ - chunks      │          │
│  │ - assets      │  │ - assets      │  │ - assets      │          │
│  └───────────────┘  └───────────────┘  └───────────────┘          │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │                    App Runner (API)                         │    │
│  │  - 0.25 vCPU, 512 MB RAM                                   │    │
│  │  - Auto-deployment on ECR push                             │    │
│  │  - Health checks: HTTP /                                    │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │                    ECR (Container Registry)                 │    │
│  │  - cloud-native-ecommerce-api                              │    │
│  │  - Image scanning enabled                                   │    │
│  │  - Lifecycle: Keep last 10 images                          │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 5.2 S3 Bucket Configuration

| Bucket | Purpose | Path Pattern | Content |
|--------|---------|--------------|---------|
| `shell-production` | Host application | `/*` | index.html, main.js, assets |
| `products-production` | Products remote | `/remotes/products/*` | remoteEntry.js, chunks |
| `product-detail-production` | Product detail remote | `/remotes/product-detail/*` | remoteEntry.js, chunks |

**Bucket Settings:**
- Public access blocked
- Versioning enabled
- CloudFront OAC access only

### 5.3 CloudFront Configuration

```hcl
# Cache Behaviors
┌──────────────────────────────────────────────────────────────┐
│  Path Pattern              │ Origin          │ TTL           │
├────────────────────────────┼─────────────────┼───────────────┤
│  /remotes/products/*       │ products S3     │ 1hr-24hr      │
│  /remotes/product-detail/* │ product-detail  │ 1hr-24hr      │
│  /* (default)              │ shell S3        │ 1hr-24hr      │
└──────────────────────────────────────────────────────────────┘

# Custom Error Responses (SPA Routing)
┌──────────────────────────────────────────────────────────────┐
│  Error Code │ Response Code │ Response Page                  │
├─────────────┼───────────────┼────────────────────────────────┤
│  403        │ 200           │ /index.html                    │
│  404        │ 200           │ /index.html                    │
└──────────────────────────────────────────────────────────────┘
```

### 5.4 App Runner Configuration

```yaml
Service Configuration:
  CPU: 256 (0.25 vCPU)
  Memory: 512 MB
  Port: 3333
  Auto-deployments: Enabled

Health Check:
  Protocol: HTTP
  Path: /
  Interval: 10s
  Timeout: 5s
  Healthy threshold: 1
  Unhealthy threshold: 5

Environment Variables:
  NODE_ENV: production
  CORS_ORIGIN: https://ecommerce.veeracs.info
```

---

## 6. Technology Stack

### 6.1 Frontend Technologies

| Category | Technology | Version | Purpose |
|----------|------------|---------|---------|
| **UI Framework** | React | 19.0.0 | Component-based UI |
| **Routing** | React Router DOM | 6.30.3 | Client-side routing |
| **Build Tool** | Webpack | 5.x | Module bundling (MFE) |
| **Build Tool** | Vite | 7.0.0 | Fast dev server (shop) |
| **Module Federation** | @nx/module-federation | 22.4.1 | Microfrontend runtime |
| **Transpiler** | SWC | 1.15.10 | Fast compilation |
| **Styling** | CSS Modules | - | Scoped component styles |

### 6.2 Backend Technologies

| Category | Technology | Version | Purpose |
|----------|------------|---------|---------|
| **Runtime** | Node.js | 20.x | JavaScript runtime |
| **Framework** | Express.js | 4.21.2 | REST API server |
| **Bundler** | esbuild | 0.19.2 | Fast backend bundling |
| **Container** | Docker | Alpine | Deployment packaging |

### 6.3 Build & DevOps

| Category | Technology | Version | Purpose |
|----------|------------|---------|---------|
| **Monorepo** | Nx | 22.4.0 | Task orchestration |
| **Package Manager** | pnpm | 8.x | Dependency management |
| **Language** | TypeScript | 5.9.2 | Type safety |
| **CI/CD** | GitHub Actions | - | Automated pipelines |
| **IaC** | Terraform | >= 1.0 | Infrastructure provisioning |

### 6.4 Testing Stack

| Category | Technology | Version | Purpose |
|----------|------------|---------|---------|
| **Unit Testing** | Vitest | 4.0.9 | Fast unit tests |
| **E2E Testing** | Playwright | 1.36.0 | Browser automation |
| **Component Testing** | @testing-library/react | 16.1.0 | React testing |
| **Coverage** | @vitest/coverage-v8 | 4.0.9 | Code coverage |

### 6.5 AWS Services

| Service | Purpose |
|---------|---------|
| **S3** | Static frontend hosting |
| **CloudFront** | CDN with SSL termination |
| **App Runner** | Managed container hosting |
| **ECR** | Docker image registry |
| **Route 53** | DNS management |
| **ACM** | SSL/TLS certificates |
| **IAM** | Access control |

---

## 7. Deployment Architecture

### 7.1 CI/CD Pipeline

```
┌─────────────────────────────────────────────────────────────────────┐
│                     GitHub Actions Pipeline                          │
│                                                                     │
│  ┌──────────────┐                                                   │
│  │  Push to     │                                                   │
│  │  main branch │                                                   │
│  └──────┬───────┘                                                   │
│         │                                                           │
│         ▼                                                           │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    CI Workflow                               │   │
│  │  ┌─────────┐    ┌─────────┐    ┌─────────┐                  │   │
│  │  │  Lint   │───▶│  Test   │───▶│  Build  │                  │   │
│  │  └─────────┘    └─────────┘    └─────────┘                  │   │
│  └──────────────────────────────────┬──────────────────────────┘   │
│                                     │                               │
│                                     ▼                               │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                   Deploy Workflow                            │   │
│  │                                                              │   │
│  │  ┌───────────────────────────────────────────────────────┐  │   │
│  │  │              build-frontend (parallel)                 │  │   │
│  │  │  ┌─────────┐  ┌──────────┐  ┌────────────────┐       │  │   │
│  │  │  │  Shell  │  │ Products │  │ Product-Detail │       │  │   │
│  │  │  └─────────┘  └──────────┘  └────────────────┘       │  │   │
│  │  └───────────────────────────────────────────────────────┘  │   │
│  │                          │                                   │   │
│  │                          ▼                                   │   │
│  │  ┌───────────────────────────────────────────────────────┐  │   │
│  │  │                   build-api                            │  │   │
│  │  │  Docker build → Push to ECR                           │  │   │
│  │  └───────────────────────────────────────────────────────┘  │   │
│  │                          │                                   │   │
│  │                          ▼                                   │   │
│  │  ┌───────────────────────────────────────────────────────┐  │   │
│  │  │                 deploy-frontend                        │  │   │
│  │  │  S3 Sync → CloudFront Invalidation                    │  │   │
│  │  └───────────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 7.2 Deployment Environments

| Environment | Frontend URL | API URL | Purpose |
|-------------|--------------|---------|---------|
| **Development** | localhost:4200 | localhost:3333 | Local development |
| **Production** | ecommerce.veeracs.info | api.veeracs.info | Live environment |

### 7.3 Independent Deployment

Each microfrontend can be deployed independently:

```yaml
# deploy-products.yml (example)
on:
  push:
    paths:
      - 'apps/products/**'
      - 'libs/shop/feature-products/**'
      - 'libs/shop/shared-ui/**'
      - 'libs/shop/data/**'
      - 'libs/shared/models/**'

jobs:
  deploy:
    steps:
      - run: npx nx build products --configuration=production
      - run: aws s3 sync dist/products s3://...-products-production
      - run: aws cloudfront create-invalidation --paths "/remotes/products/*"
```

### 7.4 Deployment Artifacts

| Artifact | Destination | Cache Strategy |
|----------|-------------|----------------|
| `shell/` | S3 shell bucket | HTML: no-cache, JS/CSS: immutable |
| `products/` | S3 products bucket | remoteEntry: short TTL, chunks: immutable |
| `product-detail/` | S3 product-detail bucket | remoteEntry: short TTL, chunks: immutable |
| `api:latest` | ECR repository | Auto-deploy on push |

---

## 8. Security Architecture

### 8.1 Network Security

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Security Layers                               │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Layer 1: Edge Security                    │   │
│  │  - CloudFront with TLS 1.2+                                 │   │
│  │  - ACM certificates (auto-renewal)                          │   │
│  │  - HTTPS redirect                                           │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Layer 2: Origin Security                  │   │
│  │  - S3: Origin Access Control (OAC)                          │   │
│  │  - S3: Public access blocked                                │   │
│  │  - App Runner: Managed TLS                                  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                   Layer 3: Application Security              │   │
│  │  - CORS configuration                                        │   │
│  │  - Input validation                                          │   │
│  │  - Error handling (no stack traces)                         │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                   Layer 4: Infrastructure Security           │   │
│  │  - IAM least privilege                                       │   │
│  │  - ECR image scanning                                        │   │
│  │  - Terraform state encryption                               │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 8.2 Security Controls

| Control | Implementation |
|---------|----------------|
| **Transport Security** | TLS 1.2+ enforced via CloudFront |
| **Access Control** | CloudFront OAC for S3 access |
| **CORS** | Configured in API for specific origins |
| **Container Security** | ECR vulnerability scanning |
| **Secrets Management** | GitHub Actions secrets for CI/CD |
| **IAM Policies** | Least privilege for App Runner ECR access |

### 8.3 S3 Security Configuration

```hcl
# Public access completely blocked
block_public_acls       = true
block_public_policy     = true
ignore_public_acls      = true
restrict_public_buckets = true

# Only CloudFront can access via OAC
Principal = { Service = "cloudfront.amazonaws.com" }
Condition = { StringEquals = { "AWS:SourceArn" = cloudfront_arn } }
```

---

## 9. Scalability & Performance

### 9.1 Scalability Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Scalability Model                               │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────┐     │
│  │                    Frontend (Static)                       │     │
│  │                                                            │     │
│  │  CloudFront: 450+ edge locations globally                 │     │
│  │  S3: Unlimited storage and requests                       │     │
│  │  Scale: Infinite (pay per request)                        │     │
│  └───────────────────────────────────────────────────────────┘     │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────┐     │
│  │                    Backend (Compute)                       │     │
│  │                                                            │     │
│  │  App Runner: Auto-scaling 1-25 instances                  │     │
│  │  Scale: Horizontal (managed)                              │     │
│  │  Warm-up: Sub-second (containers pre-warmed)              │     │
│  └───────────────────────────────────────────────────────────┘     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 9.2 Performance Optimizations

| Layer | Optimization | Impact |
|-------|--------------|--------|
| **CDN** | Global edge caching | < 50ms latency worldwide |
| **Assets** | Content hashing | Long-term browser caching |
| **Compression** | Gzip/Brotli | 60-80% size reduction |
| **Code Splitting** | Webpack chunks | Smaller initial bundle |
| **Lazy Loading** | React.lazy() | Load on demand |
| **Shared Deps** | Module Federation | Single React instance |

### 9.3 Performance Metrics (Target)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **First Contentful Paint** | < 1.5s | Lighthouse |
| **Largest Contentful Paint** | < 2.5s | Lighthouse |
| **Time to Interactive** | < 3.5s | Lighthouse |
| **Cumulative Layout Shift** | < 0.1 | Lighthouse |
| **API Response Time** | < 200ms | p95 latency |

### 9.4 Caching Strategy

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Caching Layers                                  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Browser Cache                                               │   │
│  │  - index.html: no-cache (always validate)                   │   │
│  │  - *.js (hashed): max-age=31536000, immutable               │   │
│  │  - *.css (hashed): max-age=31536000, immutable              │   │
│  │  - remoteEntry.js: max-age=0, must-revalidate               │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  CloudFront Edge Cache                                       │   │
│  │  - Default TTL: 1 hour                                       │   │
│  │  - Max TTL: 24 hours                                        │   │
│  │  - Invalidation on deploy                                   │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 10. Reliability & Fault Tolerance

### 10.1 Reliability Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Fault Tolerance Design                            │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                CloudFront (Multi-Region)                     │   │
│  │  - Automatic failover between edge locations                │   │
│  │  - Origin failover if S3 unavailable                        │   │
│  │  - 99.9% SLA                                                │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                   S3 (11 9s Durability)                      │   │
│  │  - 99.999999999% durability                                 │   │
│  │  - Cross-AZ replication (automatic)                         │   │
│  │  - Versioning enabled for rollback                          │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                 App Runner (Multi-AZ)                        │   │
│  │  - Automatic multi-AZ deployment                            │   │
│  │  - Health checks with auto-restart                          │   │
│  │  - Managed scaling                                          │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 10.2 Error Handling

#### Frontend Error Boundaries

```tsx
// React Error Boundary for remote failures
<ErrorBoundary FallbackComponent={RemoteError}>
  <Suspense fallback={<LoadingSpinner />}>
    <ProductList />
  </Suspense>
</ErrorBoundary>
```

#### API Error Handling

```typescript
// Graceful degradation
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'production' 
      ? 'Something went wrong' 
      : err.message
  });
});
```

### 10.3 Recovery Procedures

| Scenario | Recovery |
|----------|----------|
| **Frontend deploy failure** | CloudFront serves cached version |
| **API deploy failure** | App Runner auto-rollback |
| **S3 object corruption** | Restore from versioned backup |
| **Remote load failure** | Error boundary shows fallback UI |

---

## 11. Monitoring & Observability

### 11.1 Observability Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Monitoring Stack                                  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Metrics                                   │   │
│  │  - CloudFront: Requests, errors, latency                    │   │
│  │  - App Runner: CPU, memory, request count                   │   │
│  │  - S3: Request metrics, storage                             │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Logs                                      │   │
│  │  - CloudWatch Logs: App Runner application logs             │   │
│  │  - CloudFront: Access logs (optional)                       │   │
│  │  - S3: Server access logs                                   │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Tracing (Recommended)                     │   │
│  │  - AWS X-Ray integration                                    │   │
│  │  - Distributed request tracing                              │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 11.2 Key Metrics

| Service | Metric | Alert Threshold |
|---------|--------|-----------------|
| **CloudFront** | 4xx Error Rate | > 5% |
| **CloudFront** | 5xx Error Rate | > 1% |
| **CloudFront** | Origin Latency | > 1000ms |
| **App Runner** | CPU Utilization | > 80% |
| **App Runner** | Memory Utilization | > 80% |
| **App Runner** | Request Latency | > 500ms p95 |

### 11.3 Health Checks

| Component | Check | Frequency |
|-----------|-------|-----------|
| **API** | HTTP GET / | 10 seconds |
| **App Runner** | Container health | Continuous |
| **CloudFront** | Origin health | Per request |

---

## 12. Cost Analysis

### 12.1 Monthly Cost Breakdown

| Service | Configuration | Estimated Cost |
|---------|--------------|----------------|
| **S3** | 3 buckets, ~100MB storage | $0.50 - $2 |
| **CloudFront** | 10GB transfer, 100k requests | $5 - $15 |
| **Route 53** | 1 hosted zone, DNS queries | $0.50 - $1 |
| **ACM** | SSL certificate | Free |
| **App Runner** | 0.25 vCPU, 512MB | $5 - $25 |
| **ECR** | ~500MB storage | $0.50 - $1 |
| **Total** | Low traffic | **$12 - $45/month** |

### 12.2 Cost Optimization Strategies

| Strategy | Implementation | Savings |
|----------|----------------|---------|
| **Price Class** | Use PriceClass_100 (US/EU only) | ~30% on CloudFront |
| **Auto-scaling** | App Runner scales to zero | Pay per request |
| **Lifecycle Policies** | ECR: Keep 10 images | Storage costs |
| **Caching** | Long TTLs for static assets | Reduced origin requests |
| **Compression** | Gzip/Brotli enabled | Reduced transfer costs |

### 12.3 Cost Scaling

| Traffic Level | Monthly Requests | Estimated Cost |
|---------------|------------------|----------------|
| **Low** | < 100k | $12 - $25 |
| **Medium** | 100k - 1M | $25 - $75 |
| **High** | 1M - 10M | $75 - $300 |

---

## 13. Future Considerations

### 13.1 Recommended Enhancements

| Enhancement | Priority | Description |
|-------------|----------|-------------|
| **Database** | High | Add PostgreSQL/DynamoDB for persistent data |
| **Authentication** | High | Implement user auth (Cognito/Auth0) |
| **Shopping Cart** | High | Add cart functionality with session storage |
| **Search** | Medium | Elasticsearch/Algolia for advanced search |
| **Caching** | Medium | Redis/ElastiCache for API caching |
| **Analytics** | Medium | User behavior tracking |
| **A/B Testing** | Low | Feature flag infrastructure |

### 13.2 Scalability Improvements

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Future Architecture                               │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                      API Gateway                             │   │
│  │  - Rate limiting                                            │   │
│  │  - Request validation                                       │   │
│  │  - API versioning                                           │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Microservices                             │   │
│  │  - Products Service                                         │   │
│  │  - Orders Service                                           │   │
│  │  - Users Service                                            │   │
│  │  - Inventory Service                                        │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Data Layer                                │   │
│  │  - PostgreSQL (products, orders)                            │   │
│  │  - Redis (sessions, cache)                                  │   │
│  │  - S3 (images, assets)                                      │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 13.3 Additional Microfrontends

| Remote | Purpose | Team |
|--------|---------|------|
| **cart** | Shopping cart UI | Cart Team |
| **checkout** | Payment flow | Payments Team |
| **account** | User profile | Identity Team |
| **admin** | Back-office tools | Platform Team |

### 13.4 CI/CD Improvements

| Improvement | Benefit |
|-------------|---------|
| **Preview Deployments** | PR-based preview environments |
| **Canary Releases** | Gradual rollout with metrics |
| **Feature Flags** | Toggle features without deploy |
| **Automated Rollback** | Metric-based auto-rollback |

---

## Appendix

### A. Glossary

| Term | Definition |
|------|------------|
| **MFE** | Microfrontend - independently deployable frontend module |
| **Module Federation** | Webpack 5 feature for runtime module sharing |
| **Host** | Application that consumes federated modules |
| **Remote** | Application that exposes federated modules |
| **OAC** | Origin Access Control - CloudFront S3 security |
| **CDN** | Content Delivery Network |
| **SPA** | Single Page Application |

### B. Reference Architecture Diagram

```
                                    Internet Users
                                         │
                                         ▼
                              ┌──────────────────────┐
                              │    Route 53 DNS      │
                              │  veeracs.info zone   │
                              └──────────┬───────────┘
                                         │
                    ┌────────────────────┼────────────────────┐
                    │                    │                    │
                    ▼                    │                    ▼
         ┌─────────────────┐             │         ┌─────────────────┐
         │ ecommerce.      │             │         │ api.veeracs.    │
         │ veeracs.info    │             │         │ info            │
         └────────┬────────┘             │         └────────┬────────┘
                  │                      │                  │
                  ▼                      │                  ▼
         ┌─────────────────┐             │         ┌─────────────────┐
         │   CloudFront    │             │         │   App Runner    │
         │   Distribution  │             │         │   (Express.js)  │
         │   + ACM SSL     │             │         │                 │
         └────────┬────────┘             │         └────────┬────────┘
                  │                      │                  │
     ┌────────────┼────────────┐         │                  │
     │            │            │         │                  ▼
     ▼            ▼            ▼         │         ┌─────────────────┐
┌─────────┐ ┌─────────┐ ┌─────────┐      │         │      ECR        │
│S3:Shell │ │S3:Prod- │ │S3:Prod- │      │         │   Repository    │
│  (Host) │ │  ucts   │ │ Detail  │      │         └─────────────────┘
└─────────┘ └─────────┘ └─────────┘      │
     │            │            │         │
     └────────────┴────────────┘         │
                  │                      │
                  └──────────────────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │  GitHub Actions │
                  │    CI/CD        │
                  └─────────────────┘
```

### C. Related Documents

| Document | Description |
|----------|-------------|
| [TECH_STACK.md](./TECH_STACK.md) | Technology stack details |
| [MODULE_FEDERATION_GUIDE.md](./MODULE_FEDERATION_GUIDE.md) | MFE best practices |
| [NX_STRUCTURE.md](./NX_STRUCTURE.md) | Monorepo structure |
| [AWS_DEPLOYMENT.md](./AWS_DEPLOYMENT.md) | Deployment guide |
| [API_REFERENCE.md](./API_REFERENCE.md) | API documentation |
| [TESTING_GUIDE.md](./TESTING_GUIDE.md) | Testing practices |

---

**Document Owner:** Platform Team  
**Review Cycle:** Quarterly  
**Next Review:** April 2026
