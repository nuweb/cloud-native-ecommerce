# Future Enhancements Roadmap

## Cloud-Native E-Commerce Platform

**Version:** 1.0  
**Last Updated:** January 2026  
**Status:** Planning

---

## Table of Contents

1. [Overview](#1-overview)
2. [Phase 1: Data Persistence](#2-phase-1-data-persistence)
3. [Phase 2: Authentication & Authorization](#3-phase-2-authentication--authorization)
4. [Phase 3: Shopping Cart & Checkout](#4-phase-3-shopping-cart--checkout)
5. [Phase 4: Order Management](#5-phase-4-order-management)
6. [Phase 5: Payment Processing](#6-phase-5-payment-processing)
7. [Phase 6: User Experience Enhancements](#7-phase-6-user-experience-enhancements)
8. [Phase 7: Search & Discovery](#8-phase-7-search--discovery)
9. [Phase 8: Analytics & Monitoring](#9-phase-8-analytics--monitoring)
10. [Phase 9: Additional Microfrontends](#10-phase-9-additional-microfrontends)
11. [Phase 10: Advanced Infrastructure](#11-phase-10-advanced-infrastructure)
12. [Implementation Priority Matrix](#12-implementation-priority-matrix)
13. [Architecture Evolution](#13-architecture-evolution)

---

## 1. Overview

### 1.1 Purpose

This document outlines the roadmap for enhancing the Cloud-Native E-Commerce Platform from a demonstration project to a fully-featured production e-commerce system.

### 1.2 Current State

| Feature                    | Status         |
| -------------------------- | -------------- |
| Product Catalog            | ✅ Implemented |
| Product Details            | ✅ Implemented |
| Product Search & Filtering | ✅ Implemented |
| REST API                   | ✅ Implemented |
| Microfrontend Architecture | ✅ Implemented |
| AWS Deployment             | ✅ Implemented |
| CI/CD Pipeline             | ✅ Implemented |

### 1.3 Target State

| Feature              | Priority    |
| -------------------- | ----------- |
| Database Integration | 🔴 Critical |
| User Authentication  | 🔴 Critical |
| Shopping Cart        | 🔴 Critical |
| Checkout Flow        | 🔴 Critical |
| Order Management     | 🟡 High     |
| Payment Processing   | 🟡 High     |
| User Profiles        | 🟡 High     |
| Advanced Search      | 🟢 Medium   |
| Analytics            | 🟢 Medium   |
| Recommendations      | 🔵 Low      |

---

## 2. Phase 1: Data Persistence

### 2.1 Overview

Replace in-memory data storage with persistent database solutions.

### 2.2 Database Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Database Architecture                             │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Primary Database (PostgreSQL)                 │   │
│  │                                                                  │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │   │
│  │  │   Products   │  │    Users     │  │    Orders    │          │   │
│  │  │              │  │              │  │              │          │   │
│  │  │  - id        │  │  - id        │  │  - id        │          │   │
│  │  │  - name      │  │  - email     │  │  - user_id   │          │   │
│  │  │  - price     │  │  - password  │  │  - status    │          │   │
│  │  │  - category  │  │  - profile   │  │  - total     │          │   │
│  │  │  - stock     │  │  - created   │  │  - items     │          │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘          │   │
│  │                                                                  │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │   │
│  │  │  Categories  │  │    Carts     │  │   Reviews    │          │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Cache Layer (Redis)                           │   │
│  │                                                                  │   │
│  │  - Session storage                                              │   │
│  │  - Product cache                                                │   │
│  │  - Cart data (temporary)                                        │   │
│  │  - Rate limiting                                                │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Object Storage (S3)                           │   │
│  │                                                                  │   │
│  │  - Product images                                               │   │
│  │  - User uploads                                                 │   │
│  │  - Invoice PDFs                                                 │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.3 Database Options

#### Option A: Amazon RDS (PostgreSQL) - Recommended

| Aspect       | Details                                |
| ------------ | -------------------------------------- |
| **Service**  | Amazon RDS for PostgreSQL              |
| **Instance** | db.t3.micro (dev) / db.t3.small (prod) |
| **Storage**  | 20GB GP2 SSD                           |
| **Multi-AZ** | Yes (production)                       |
| **Backup**   | Automated daily backups                |
| **Cost**     | ~$15-50/month                          |

```hcl
# Terraform Configuration
resource "aws_db_instance" "main" {
  identifier        = "cloud-native-ecommerce"
  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = "db.t3.small"
  allocated_storage = 20

  db_name  = "ecommerce"
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  multi_az               = true
  backup_retention_period = 7
  skip_final_snapshot    = false

  tags = {
    Name = "cloud-native-ecommerce-db"
  }
}
```

#### Option B: Amazon DynamoDB (NoSQL)

| Aspect       | Details                                    |
| ------------ | ------------------------------------------ |
| **Service**  | Amazon DynamoDB                            |
| **Capacity** | On-demand                                  |
| **Tables**   | Products, Users, Orders, Carts             |
| **Cost**     | Pay per request (~$1-10/month low traffic) |

**Best for:** High-scale, simple access patterns

#### Option C: PlanetScale (Serverless MySQL)

| Aspect       | Details                                |
| ------------ | -------------------------------------- |
| **Service**  | PlanetScale                            |
| **Plan**     | Hobby (free) / Scaler                  |
| **Features** | Branching, non-blocking schema changes |
| **Cost**     | Free tier available                    |

**Best for:** Serverless-first, easy scaling

### 2.4 Database Schema

```sql
-- Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products Table
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    compare_at_price DECIMAL(10, 2),
    sku VARCHAR(100) UNIQUE,
    stock INTEGER DEFAULT 0,
    category_id UUID REFERENCES categories(id),
    image_url VARCHAR(500),
    images JSONB DEFAULT '[]',
    rating DECIMAL(3, 2) DEFAULT 0,
    review_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Categories Table
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    parent_id UUID REFERENCES categories(id),
    image_url VARCHAR(500),
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE
);

-- Addresses Table
CREATE TABLE addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(20) DEFAULT 'shipping', -- shipping, billing
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(2) NOT NULL, -- ISO 3166-1 alpha-2
    phone VARCHAR(20),
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Carts Table
CREATE TABLE carts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    session_id VARCHAR(255), -- For guest carts
    status VARCHAR(20) DEFAULT 'active', -- active, abandoned, converted
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Cart Items Table
CREATE TABLE cart_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cart_id UUID REFERENCES carts(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    quantity INTEGER NOT NULL DEFAULT 1,
    price_at_add DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(cart_id, product_id)
);

-- Orders Table
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    user_id UUID REFERENCES users(id),
    status VARCHAR(50) DEFAULT 'pending',
    subtotal DECIMAL(10, 2) NOT NULL,
    tax DECIMAL(10, 2) DEFAULT 0,
    shipping_cost DECIMAL(10, 2) DEFAULT 0,
    discount DECIMAL(10, 2) DEFAULT 0,
    total DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    shipping_address JSONB,
    billing_address JSONB,
    payment_method VARCHAR(50),
    payment_status VARCHAR(50) DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Order Items Table
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    product_name VARCHAR(255) NOT NULL,
    product_sku VARCHAR(100),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Reviews Table
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(255),
    comment TEXT,
    is_verified_purchase BOOLEAN DEFAULT FALSE,
    is_approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_slug ON products(slug);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_cart_items_cart ON cart_items(cart_id);
CREATE INDEX idx_reviews_product ON reviews(product_id);
```

### 2.5 Redis Cache Layer

```typescript
// Redis Configuration
interface CacheConfig {
  host: string;
  port: number;
  password?: string;
  tls?: boolean;
}

// Cache Keys Structure
const CACHE_KEYS = {
  product: (id: string) => `product:${id}`,
  productList: (page: number, filters: string) => `products:${page}:${filters}`,
  categories: () => 'categories:all',
  cart: (userId: string) => `cart:${userId}`,
  session: (sessionId: string) => `session:${sessionId}`,
  rateLimit: (ip: string) => `rate:${ip}`,
};

// Cache TTL (seconds)
const CACHE_TTL = {
  product: 3600, // 1 hour
  productList: 300, // 5 minutes
  categories: 3600, // 1 hour
  cart: 86400, // 24 hours
  session: 604800, // 7 days
};
```

### 2.6 AWS Services for Data Layer

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    AWS Data Services                                     │
│                                                                         │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐        │
│  │   Amazon RDS    │  │ Amazon ElastiCache│ │   Amazon S3    │        │
│  │   (PostgreSQL)  │  │   (Redis)        │  │   (Images)     │        │
│  │                 │  │                   │  │                │        │
│  │  - Products     │  │  - Sessions       │  │  - Product     │        │
│  │  - Users        │  │  - Cart cache     │  │    images      │        │
│  │  - Orders       │  │  - Rate limiting  │  │  - Thumbnails  │        │
│  │  - Reviews      │  │  - API cache      │  │  - Invoices    │        │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.7 Implementation Tasks

- [ ] Set up Amazon RDS PostgreSQL instance
- [ ] Create database schema with migrations
- [ ] Implement repository pattern for data access
- [ ] Set up Amazon ElastiCache (Redis)
- [ ] Implement caching layer
- [ ] Create S3 bucket for product images
- [ ] Implement image upload API
- [ ] Add database connection to API service
- [ ] Update Terraform infrastructure

---

## 3. Phase 2: Authentication & Authorization

### 3.1 Overview

Implement secure user authentication and role-based access control.

### 3.2 Authentication Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Authentication Flow                                   │
│                                                                         │
│   ┌──────────┐      ┌──────────────┐      ┌──────────────┐             │
│   │  Client  │─────▶│   API        │─────▶│   Cognito/   │             │
│   │  (React) │      │   Gateway    │      │   Auth0      │             │
│   └──────────┘      └──────────────┘      └──────────────┘             │
│        │                   │                     │                      │
│        │                   │                     │                      │
│        │    1. Login Request                     │                      │
│        │──────────────────────────────────────────▶                     │
│        │                                         │                      │
│        │    2. Validate Credentials              │                      │
│        │                   ◀────────────────────▶│                      │
│        │                                         │                      │
│        │    3. Return JWT Tokens                 │                      │
│        │◀──────────────────────────────────────────                     │
│        │                                         │                      │
│        │    4. API Request + Access Token        │                      │
│        │──────────────────▶│                     │                      │
│        │                   │                     │                      │
│        │    5. Verify Token│                     │                      │
│        │                   │────────────────────▶│                      │
│        │                   │◀────────────────────│                      │
│        │                   │                     │                      │
│        │    6. Response    │                     │                      │
│        │◀──────────────────│                     │                      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.3 Authentication Options

#### Option A: Amazon Cognito - Recommended

| Feature         | Details                             |
| --------------- | ----------------------------------- |
| **Service**     | AWS Cognito User Pools              |
| **Features**    | Sign-up, Sign-in, MFA, Social login |
| **Integration** | Native AWS, easy with Amplify       |
| **Cost**        | Free tier: 50,000 MAU               |

```hcl
# Terraform - Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "cloud-native-ecommerce-users"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Verify your email"
    email_message        = "Your verification code is {####}"
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true
    required            = true
  }

  schema {
    name                = "name"
    attribute_data_type = "String"
    mutable             = true
    required            = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

resource "aws_cognito_user_pool_client" "web" {
  name         = "web-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret     = false
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  supported_identity_providers = ["COGNITO", "Google", "Facebook"]

  callback_urls = [
    "https://ecommerce.veeracs.info/auth/callback",
    "http://localhost:4200/auth/callback"
  ]

  logout_urls = [
    "https://ecommerce.veeracs.info/auth/logout",
    "http://localhost:4200/auth/logout"
  ]

  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  allowed_oauth_flows_user_pool_client = true
}
```

#### Option B: Auth0

| Feature      | Details                                 |
| ------------ | --------------------------------------- |
| **Service**  | Auth0 by Okta                           |
| **Features** | Universal login, extensive integrations |
| **SDKs**     | @auth0/auth0-react                      |
| **Cost**     | Free tier: 7,000 MAU                    |

#### Option C: Custom JWT Implementation

| Feature      | Details                         |
| ------------ | ------------------------------- |
| **Library**  | jsonwebtoken, bcrypt            |
| **Storage**  | PostgreSQL + Redis              |
| **Features** | Full control, no vendor lock-in |
| **Cost**     | Infrastructure only             |

### 3.4 Authorization Model (RBAC)

```typescript
// Role Definitions
enum Role {
  GUEST = 'guest',
  CUSTOMER = 'customer',
  ADMIN = 'admin',
  SUPER_ADMIN = 'super_admin',
}

// Permission Definitions
enum Permission {
  // Products
  READ_PRODUCTS = 'products:read',
  CREATE_PRODUCT = 'products:create',
  UPDATE_PRODUCT = 'products:update',
  DELETE_PRODUCT = 'products:delete',

  // Orders
  READ_OWN_ORDERS = 'orders:read:own',
  READ_ALL_ORDERS = 'orders:read:all',
  UPDATE_ORDER_STATUS = 'orders:update:status',

  // Users
  READ_OWN_PROFILE = 'users:read:own',
  UPDATE_OWN_PROFILE = 'users:update:own',
  READ_ALL_USERS = 'users:read:all',
  MANAGE_USERS = 'users:manage',

  // Cart
  MANAGE_OWN_CART = 'cart:manage:own',

  // Reviews
  CREATE_REVIEW = 'reviews:create',
  DELETE_OWN_REVIEW = 'reviews:delete:own',
  MODERATE_REVIEWS = 'reviews:moderate',
}

// Role-Permission Mapping
const ROLE_PERMISSIONS: Record<Role, Permission[]> = {
  [Role.GUEST]: [Permission.READ_PRODUCTS],

  [Role.CUSTOMER]: [
    Permission.READ_PRODUCTS,
    Permission.READ_OWN_ORDERS,
    Permission.READ_OWN_PROFILE,
    Permission.UPDATE_OWN_PROFILE,
    Permission.MANAGE_OWN_CART,
    Permission.CREATE_REVIEW,
    Permission.DELETE_OWN_REVIEW,
  ],

  [Role.ADMIN]: [
    Permission.READ_PRODUCTS,
    Permission.CREATE_PRODUCT,
    Permission.UPDATE_PRODUCT,
    Permission.READ_ALL_ORDERS,
    Permission.UPDATE_ORDER_STATUS,
    Permission.READ_ALL_USERS,
    Permission.MODERATE_REVIEWS,
  ],

  [Role.SUPER_ADMIN]: [
    // All permissions
    ...Object.values(Permission),
  ],
};
```

### 3.5 Frontend Auth Integration

```typescript
// libs/shop/auth/src/lib/auth-context.tsx
import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { CognitoUser, AuthenticationDetails } from 'amazon-cognito-identity-js';

interface User {
  id: string;
  email: string;
  name: string;
  role: Role;
}

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  register: (email: string, password: string, name: string) => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Check for existing session
    checkAuthStatus();
  }, []);

  const login = async (email: string, password: string) => {
    // Cognito authentication
  };

  const logout = async () => {
    // Clear session
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        isAuthenticated: !!user,
        isLoading,
        login,
        logout,
        register,
        resetPassword,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};
```

### 3.6 Protected Routes

```typescript
// libs/shop/auth/src/lib/protected-route.tsx
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from './auth-context';
import { LoadingSpinner } from '@org/shop-shared-ui';

interface ProtectedRouteProps {
  children: React.ReactNode;
  requiredRole?: Role;
}

export function ProtectedRoute({ children, requiredRole }: ProtectedRouteProps) {
  const { isAuthenticated, isLoading, user } = useAuth();
  const location = useLocation();

  if (isLoading) {
    return <LoadingSpinner />;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  if (requiredRole && user?.role !== requiredRole) {
    return <Navigate to="/unauthorized" replace />;
  }

  return <>{children}</>;
}
```

### 3.7 API Authentication Middleware

```typescript
// libs/api/auth/src/lib/auth-middleware.ts
import { Request, Response, NextFunction } from 'express';
import { CognitoJwtVerifier } from 'aws-jwt-verify';

const verifier = CognitoJwtVerifier.create({
  userPoolId: process.env.COGNITO_USER_POOL_ID!,
  tokenUse: 'access',
  clientId: process.env.COGNITO_CLIENT_ID!,
});

export async function authMiddleware(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const payload = await verifier.verify(token);
    req.user = {
      id: payload.sub,
      email: payload.email as string,
      role: (payload['custom:role'] as Role) || Role.CUSTOMER,
    };
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

export function requireRole(...roles: Role[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Not authenticated' });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    next();
  };
}
```

### 3.8 Social Login Integration

```typescript
// Cognito Identity Provider Configuration
const socialProviders = {
  google: {
    clientId: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    scopes: ['email', 'profile', 'openid'],
  },
  facebook: {
    clientId: process.env.FACEBOOK_APP_ID,
    clientSecret: process.env.FACEBOOK_APP_SECRET,
    scopes: ['email', 'public_profile'],
  },
  apple: {
    clientId: process.env.APPLE_CLIENT_ID,
    teamId: process.env.APPLE_TEAM_ID,
    keyId: process.env.APPLE_KEY_ID,
    privateKey: process.env.APPLE_PRIVATE_KEY,
  },
};
```

### 3.9 Implementation Tasks

- [ ] Set up Amazon Cognito User Pool
- [ ] Configure Cognito App Client
- [ ] Implement frontend auth context
- [ ] Create login/register pages
- [ ] Add protected routes
- [ ] Implement API auth middleware
- [ ] Add social login (Google, Facebook)
- [ ] Implement password reset flow
- [ ] Add email verification
- [ ] Create admin role management

---

## 4. Phase 3: Shopping Cart & Checkout

### 4.1 Overview

Implement a full shopping cart with guest and authenticated user support.

### 4.2 Cart Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Shopping Cart Architecture                        │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Client (React)                                │   │
│  │                                                                  │   │
│  │  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │   │
│  │  │  CartContext │───▶│  useCart()   │───▶│  CartDrawer  │      │   │
│  │  │  (State)     │    │  (Hook)      │    │  (UI)        │      │   │
│  │  └──────────────┘    └──────────────┘    └──────────────┘      │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    API Layer                                     │   │
│  │                                                                  │   │
│  │  POST /api/cart/items      - Add item                           │   │
│  │  PUT  /api/cart/items/:id  - Update quantity                    │   │
│  │  DELETE /api/cart/items/:id - Remove item                       │   │
│  │  GET  /api/cart            - Get cart                           │   │
│  │  POST /api/cart/merge      - Merge guest cart with user cart    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Storage Layer                                 │   │
│  │                                                                  │   │
│  │  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │   │
│  │  │ LocalStorage │    │    Redis     │    │  PostgreSQL  │      │   │
│  │  │ (Guest cart) │    │  (Session)   │    │  (Persisted) │      │   │
│  │  └──────────────┘    └──────────────┘    └──────────────┘      │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.3 Cart Data Models

```typescript
// libs/shared/models/src/lib/cart.ts
interface CartItem {
  id: string;
  productId: string;
  product: Product;
  quantity: number;
  priceAtAdd: number;
  addedAt: Date;
}

interface Cart {
  id: string;
  userId?: string;
  sessionId?: string;
  items: CartItem[];
  subtotal: number;
  itemCount: number;
  createdAt: Date;
  updatedAt: Date;
}

interface AddToCartRequest {
  productId: string;
  quantity: number;
}

interface UpdateCartItemRequest {
  quantity: number;
}
```

### 4.4 Cart Context & Hook

```typescript
// libs/shop/cart/src/lib/cart-context.tsx
interface CartContextType {
  cart: Cart | null;
  isLoading: boolean;
  itemCount: number;
  subtotal: number;
  addItem: (productId: string, quantity?: number) => Promise<void>;
  updateItem: (itemId: string, quantity: number) => Promise<void>;
  removeItem: (itemId: string) => Promise<void>;
  clearCart: () => Promise<void>;
}

export function CartProvider({ children }: { children: ReactNode }) {
  const [cart, setCart] = useState<Cart | null>(null);
  const { isAuthenticated, user } = useAuth();

  useEffect(() => {
    loadCart();
  }, [isAuthenticated]);

  const loadCart = async () => {
    if (isAuthenticated) {
      // Fetch cart from API
      const response = await fetch('/api/cart', {
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      setCart(await response.json());
    } else {
      // Load from localStorage
      const localCart = localStorage.getItem('guest_cart');
      if (localCart) {
        setCart(JSON.parse(localCart));
      }
    }
  };

  const addItem = async (productId: string, quantity = 1) => {
    if (isAuthenticated) {
      const response = await fetch('/api/cart/items', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${getToken()}`,
        },
        body: JSON.stringify({ productId, quantity }),
      });
      setCart(await response.json());
    } else {
      // Add to localStorage cart
      const updatedCart = addToLocalCart(cart, productId, quantity);
      setCart(updatedCart);
      localStorage.setItem('guest_cart', JSON.stringify(updatedCart));
    }
  };

  // ... other methods

  return (
    <CartContext.Provider
      value={{
        cart,
        isLoading,
        itemCount: cart?.itemCount || 0,
        subtotal: cart?.subtotal || 0,
        addItem,
        updateItem,
        removeItem,
        clearCart,
      }}
    >
      {children}
    </CartContext.Provider>
  );
}
```

### 4.5 Cart UI Components

```typescript
// libs/shop/cart/src/lib/cart-drawer.tsx
export function CartDrawer({ isOpen, onClose }: CartDrawerProps) {
  const { cart, updateItem, removeItem } = useCart();

  return (
    <Drawer isOpen={isOpen} onClose={onClose} position="right">
      <DrawerHeader>
        <h2>Your Cart ({cart?.itemCount || 0})</h2>
        <button onClick={onClose}>×</button>
      </DrawerHeader>

      <DrawerBody>
        {cart?.items.length === 0 ? (
          <EmptyCartMessage />
        ) : (
          <ul className="cart-items">
            {cart?.items.map((item) => (
              <CartItemRow
                key={item.id}
                item={item}
                onUpdateQuantity={(qty) => updateItem(item.id, qty)}
                onRemove={() => removeItem(item.id)}
              />
            ))}
          </ul>
        )}
      </DrawerBody>

      <DrawerFooter>
        <div className="cart-subtotal">
          <span>Subtotal:</span>
          <span>${cart?.subtotal.toFixed(2)}</span>
        </div>
        <Link to="/checkout" onClick={onClose}>
          <Button variant="primary" fullWidth>
            Proceed to Checkout
          </Button>
        </Link>
      </DrawerFooter>
    </Drawer>
  );
}
```

### 4.6 Checkout Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Checkout Flow                                     │
│                                                                         │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐         │
│  │   Cart   │───▶│ Shipping │───▶│ Payment  │───▶│ Confirm  │         │
│  │  Review  │    │  Address │    │  Method  │    │  Order   │         │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘         │
│       │               │               │               │                 │
│       ▼               ▼               ▼               ▼                 │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐         │
│  │ Validate │    │  Save    │    │ Validate │    │  Create  │         │
│  │  Items   │    │ Address  │    │  Payment │    │  Order   │         │
│  │  Stock   │    │          │    │          │    │          │         │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘         │
│                                                       │                 │
│                                                       ▼                 │
│                                              ┌──────────────┐           │
│                                              │ Order        │           │
│                                              │ Confirmation │           │
│                                              │ Page         │           │
│                                              └──────────────┘           │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.7 Checkout Page Structure

```typescript
// apps/checkout/src/app/checkout-page.tsx
export function CheckoutPage() {
  const [step, setStep] = useState<CheckoutStep>('cart');
  const { cart } = useCart();
  const { isAuthenticated } = useAuth();

  const steps: CheckoutStep[] = ['cart', 'shipping', 'payment', 'confirm'];

  return (
    <div className="checkout-page">
      <CheckoutProgress currentStep={step} steps={steps} />

      <div className="checkout-content">
        <div className="checkout-main">
          {step === 'cart' && <CartReview onNext={() => setStep('shipping')} />}
          {step === 'shipping' && (
            <ShippingForm onBack={() => setStep('cart')} onNext={() => setStep('payment')} />
          )}
          {step === 'payment' && (
            <PaymentForm onBack={() => setStep('shipping')} onNext={() => setStep('confirm')} />
          )}
          {step === 'confirm' && <OrderConfirmation onBack={() => setStep('payment')} />}
        </div>

        <div className="checkout-sidebar">
          <OrderSummary cart={cart} />
        </div>
      </div>
    </div>
  );
}
```

### 4.8 Implementation Tasks

- [ ] Create cart library (`libs/shop/cart`)
- [ ] Implement CartContext and useCart hook
- [ ] Build cart API endpoints
- [ ] Create CartDrawer component
- [ ] Implement guest cart with localStorage
- [ ] Add cart merge on login
- [ ] Create checkout microfrontend
- [ ] Build checkout steps (shipping, payment, confirm)
- [ ] Implement address management
- [ ] Add order summary component

---

## 5. Phase 4: Order Management

### 5.1 Overview

Implement complete order lifecycle management.

### 5.2 Order State Machine

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Order State Machine                               │
│                                                                         │
│                           ┌──────────┐                                  │
│                           │  PENDING │                                  │
│                           └────┬─────┘                                  │
│                                │                                        │
│            ┌───────────────────┼───────────────────┐                   │
│            │                   │                   │                    │
│            ▼                   ▼                   ▼                    │
│     ┌──────────┐        ┌──────────┐        ┌──────────┐              │
│     │ PAYMENT  │        │ PAYMENT  │        │ CANCELLED│              │
│     │ PENDING  │        │ FAILED   │        │          │              │
│     └────┬─────┘        └──────────┘        └──────────┘              │
│          │                                                             │
│          ▼                                                             │
│     ┌──────────┐                                                       │
│     │  PAID    │                                                       │
│     └────┬─────┘                                                       │
│          │                                                             │
│          ▼                                                             │
│     ┌──────────┐                                                       │
│     │PROCESSING│                                                       │
│     └────┬─────┘                                                       │
│          │                                                             │
│          ▼                                                             │
│     ┌──────────┐                                                       │
│     │ SHIPPED  │                                                       │
│     └────┬─────┘                                                       │
│          │                                                             │
│     ┌────┴────┐                                                        │
│     │         │                                                        │
│     ▼         ▼                                                        │
│┌──────────┐ ┌──────────┐                                              │
││DELIVERED │ │ RETURNED │                                              │
│└──────────┘ └──────────┘                                              │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.3 Order API Endpoints

```typescript
// Order API Routes
router.post('/orders', authMiddleware, createOrder);
router.get('/orders', authMiddleware, getOrders);
router.get('/orders/:id', authMiddleware, getOrderById);
router.put('/orders/:id/status', authMiddleware, requireRole('admin'), updateOrderStatus);
router.post('/orders/:id/cancel', authMiddleware, cancelOrder);
router.get('/orders/:id/invoice', authMiddleware, generateInvoice);

// Admin Routes
router.get('/admin/orders', authMiddleware, requireRole('admin'), getAllOrders);
router.get('/admin/orders/stats', authMiddleware, requireRole('admin'), getOrderStats);
```

### 5.4 Order Service

```typescript
// libs/api/orders/src/lib/orders.service.ts
export class OrdersService {
  async createOrder(userId: string, cartId: string, data: CreateOrderDto): Promise<Order> {
    return await this.db.transaction(async (tx) => {
      // 1. Get cart items
      const cart = await tx.query('SELECT * FROM carts WHERE id = $1', [cartId]);
      const items = await tx.query('SELECT * FROM cart_items WHERE cart_id = $1', [cartId]);

      // 2. Validate stock
      for (const item of items) {
        const product = await tx.query('SELECT stock FROM products WHERE id = $1', [
          item.product_id,
        ]);
        if (product.stock < item.quantity) {
          throw new Error(`Insufficient stock for ${item.product_id}`);
        }
      }

      // 3. Create order
      const orderNumber = this.generateOrderNumber();
      const order = await tx.query(
        `
        INSERT INTO orders (order_number, user_id, subtotal, tax, shipping_cost, total, shipping_address, billing_address)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING *
      `,
        [
          orderNumber,
          userId,
          data.subtotal,
          data.tax,
          data.shippingCost,
          data.total,
          data.shippingAddress,
          data.billingAddress,
        ]
      );

      // 4. Create order items
      for (const item of items) {
        await tx.query(
          `
          INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, total_price)
          VALUES ($1, $2, $3, $4, $5, $6)
        `,
          [
            order.id,
            item.product_id,
            item.product_name,
            item.quantity,
            item.unit_price,
            item.total_price,
          ]
        );
      }

      // 5. Update stock
      for (const item of items) {
        await tx.query('UPDATE products SET stock = stock - $1 WHERE id = $2', [
          item.quantity,
          item.product_id,
        ]);
      }

      // 6. Clear cart
      await tx.query('DELETE FROM cart_items WHERE cart_id = $1', [cartId]);
      await tx.query('UPDATE carts SET status = $1 WHERE id = $2', ['converted', cartId]);

      // 7. Send confirmation email
      await this.emailService.sendOrderConfirmation(order);

      return order;
    });
  }

  async updateOrderStatus(orderId: string, status: OrderStatus): Promise<Order> {
    const validTransitions: Record<OrderStatus, OrderStatus[]> = {
      pending: ['payment_pending', 'cancelled'],
      payment_pending: ['paid', 'payment_failed', 'cancelled'],
      paid: ['processing', 'cancelled'],
      processing: ['shipped'],
      shipped: ['delivered', 'returned'],
      delivered: ['returned'],
    };

    const order = await this.getById(orderId);

    if (!validTransitions[order.status]?.includes(status)) {
      throw new Error(`Invalid status transition: ${order.status} -> ${status}`);
    }

    return await this.db.query(
      'UPDATE orders SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
      [status, orderId]
    );
  }
}
```

### 5.5 Order History UI

```typescript
// libs/shop/feature-orders/src/lib/order-history.tsx
export function OrderHistory() {
  const { orders, isLoading } = useOrders();

  return (
    <div className="order-history">
      <h1>Order History</h1>

      {isLoading ? (
        <LoadingSpinner />
      ) : orders.length === 0 ? (
        <EmptyState message="No orders yet" />
      ) : (
        <div className="orders-list">
          {orders.map((order) => (
            <OrderCard key={order.id} order={order} />
          ))}
        </div>
      )}
    </div>
  );
}

function OrderCard({ order }: { order: Order }) {
  return (
    <div className="order-card">
      <div className="order-header">
        <span className="order-number">Order #{order.orderNumber}</span>
        <OrderStatusBadge status={order.status} />
      </div>

      <div className="order-date">Placed on {formatDate(order.createdAt)}</div>

      <div className="order-items">
        {order.items.slice(0, 3).map((item) => (
          <OrderItemPreview key={item.id} item={item} />
        ))}
        {order.items.length > 3 && <span>+{order.items.length - 3} more items</span>}
      </div>

      <div className="order-footer">
        <span className="order-total">Total: ${order.total.toFixed(2)}</span>
        <Link to={`/orders/${order.id}`}>View Details</Link>
      </div>
    </div>
  );
}
```

### 5.6 Implementation Tasks

- [ ] Create orders library (`libs/api/orders`)
- [ ] Implement order state machine
- [ ] Build order API endpoints
- [ ] Create order confirmation emails
- [ ] Implement order history page
- [ ] Build order detail page
- [ ] Add order tracking
- [ ] Create admin order management
- [ ] Implement invoice generation

---

## 6. Phase 5: Payment Processing

### 6.1 Overview

Integrate secure payment processing with Stripe.

### 6.2 Payment Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Payment Flow (Stripe)                             │
│                                                                         │
│  ┌──────────┐      ┌──────────────┐      ┌──────────────┐              │
│  │  Client  │─────▶│   API        │─────▶│   Stripe     │              │
│  │  (React) │      │   Server     │      │   API        │              │
│  └──────────┘      └──────────────┘      └──────────────┘              │
│       │                   │                     │                       │
│       │ 1. Create PaymentIntent                 │                       │
│       │──────────────────▶│                     │                       │
│       │                   │ 2. Create Intent    │                       │
│       │                   │────────────────────▶│                       │
│       │                   │ 3. Client Secret    │                       │
│       │                   │◀────────────────────│                       │
│       │ 4. Client Secret  │                     │                       │
│       │◀──────────────────│                     │                       │
│       │                                         │                       │
│       │ 5. Confirm Payment (Stripe.js)          │                       │
│       │────────────────────────────────────────▶│                       │
│       │                                         │                       │
│       │ 6. Payment Result                       │                       │
│       │◀────────────────────────────────────────│                       │
│       │                                         │                       │
│       │                   │ 7. Webhook Event    │                       │
│       │                   │◀────────────────────│                       │
│       │                   │                     │                       │
│       │                   │ 8. Update Order     │                       │
│       │                   │                     │                       │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 6.3 Stripe Integration

```typescript
// libs/api/payments/src/lib/stripe.service.ts
import Stripe from 'stripe';

export class StripeService {
  private stripe: Stripe;

  constructor() {
    this.stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
      apiVersion: '2023-10-16',
    });
  }

  async createPaymentIntent(
    orderId: string,
    amount: number,
    currency = 'usd'
  ): Promise<Stripe.PaymentIntent> {
    return await this.stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Convert to cents
      currency,
      metadata: {
        orderId,
      },
      automatic_payment_methods: {
        enabled: true,
      },
    });
  }

  async confirmPayment(paymentIntentId: string): Promise<Stripe.PaymentIntent> {
    return await this.stripe.paymentIntents.retrieve(paymentIntentId);
  }

  async createRefund(paymentIntentId: string, amount?: number): Promise<Stripe.Refund> {
    return await this.stripe.refunds.create({
      payment_intent: paymentIntentId,
      amount: amount ? Math.round(amount * 100) : undefined,
    });
  }

  constructWebhookEvent(payload: Buffer, signature: string): Stripe.Event {
    return this.stripe.webhooks.constructEvent(
      payload,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  }
}
```

### 6.4 Payment Webhook Handler

```typescript
// apps/api/src/routes/webhooks.ts
router.post('/webhooks/stripe', express.raw({ type: 'application/json' }), async (req, res) => {
  const signature = req.headers['stripe-signature'] as string;

  try {
    const event = stripeService.constructWebhookEvent(req.body, signature);

    switch (event.type) {
      case 'payment_intent.succeeded':
        await handlePaymentSuccess(event.data.object as Stripe.PaymentIntent);
        break;
      case 'payment_intent.payment_failed':
        await handlePaymentFailure(event.data.object as Stripe.PaymentIntent);
        break;
      case 'charge.refunded':
        await handleRefund(event.data.object as Stripe.Charge);
        break;
    }

    res.json({ received: true });
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(400).send(`Webhook Error: ${error.message}`);
  }
});

async function handlePaymentSuccess(paymentIntent: Stripe.PaymentIntent) {
  const orderId = paymentIntent.metadata.orderId;
  await ordersService.updateOrderStatus(orderId, 'paid');
  await ordersService.updatePaymentStatus(orderId, 'completed', paymentIntent.id);
  await emailService.sendPaymentConfirmation(orderId);
}
```

### 6.5 Frontend Payment Form

```typescript
// libs/shop/checkout/src/lib/payment-form.tsx
import { loadStripe } from '@stripe/stripe-js';
import { Elements, PaymentElement, useStripe, useElements } from '@stripe/react-stripe-js';

const stripePromise = loadStripe(process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY!);

export function PaymentForm({ clientSecret, onSuccess }: PaymentFormProps) {
  return (
    <Elements stripe={stripePromise} options={{ clientSecret }}>
      <CheckoutForm onSuccess={onSuccess} />
    </Elements>
  );
}

function CheckoutForm({ onSuccess }: { onSuccess: () => void }) {
  const stripe = useStripe();
  const elements = useElements();
  const [isProcessing, setIsProcessing] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string>();

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();

    if (!stripe || !elements) return;

    setIsProcessing(true);
    setErrorMessage(undefined);

    const { error, paymentIntent } = await stripe.confirmPayment({
      elements,
      confirmParams: {
        return_url: `${window.location.origin}/checkout/complete`,
      },
      redirect: 'if_required',
    });

    if (error) {
      setErrorMessage(error.message);
      setIsProcessing(false);
    } else if (paymentIntent?.status === 'succeeded') {
      onSuccess();
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <PaymentElement />

      {errorMessage && <div className="error-message">{errorMessage}</div>}

      <button type="submit" disabled={!stripe || isProcessing}>
        {isProcessing ? 'Processing...' : 'Pay Now'}
      </button>
    </form>
  );
}
```

### 6.6 Supported Payment Methods

| Method                 | Implementation                |
| ---------------------- | ----------------------------- |
| **Credit/Debit Cards** | Stripe Payment Element        |
| **Apple Pay**          | Stripe Payment Request Button |
| **Google Pay**         | Stripe Payment Request Button |
| **PayPal**             | PayPal JS SDK integration     |
| **Buy Now Pay Later**  | Klarna/Afterpay via Stripe    |

### 6.7 Implementation Tasks

- [ ] Set up Stripe account and API keys
- [ ] Create payments library (`libs/api/payments`)
- [ ] Implement payment intent creation
- [ ] Build webhook handler
- [ ] Create frontend payment form
- [ ] Add Apple Pay / Google Pay
- [ ] Implement refund functionality
- [ ] Add payment error handling
- [ ] Create payment receipts

---

## 7. Phase 6: User Experience Enhancements

### 7.1 Wishlist Feature

```typescript
// libs/shop/wishlist/src/lib/wishlist.service.ts
interface WishlistItem {
  id: string;
  userId: string;
  productId: string;
  product: Product;
  addedAt: Date;
}

export class WishlistService {
  async addToWishlist(userId: string, productId: string): Promise<WishlistItem>;
  async removeFromWishlist(userId: string, productId: string): Promise<void>;
  async getWishlist(userId: string): Promise<WishlistItem[]>;
  async isInWishlist(userId: string, productId: string): Promise<boolean>;
  async moveToCart(userId: string, productId: string): Promise<void>;
}
```

### 7.2 Product Reviews

```typescript
// libs/shop/reviews/src/lib/review-form.tsx
export function ReviewForm({ productId, onSubmit }: ReviewFormProps) {
  const [rating, setRating] = useState(0);
  const [title, setTitle] = useState('');
  const [comment, setComment] = useState('');

  return (
    <form onSubmit={handleSubmit}>
      <StarRating value={rating} onChange={setRating} />

      <input
        type="text"
        placeholder="Review title"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
      />

      <textarea
        placeholder="Write your review..."
        value={comment}
        onChange={(e) => setComment(e.target.value)}
      />

      <button type="submit">Submit Review</button>
    </form>
  );
}
```

### 7.3 Product Recommendations

```typescript
// libs/api/recommendations/src/lib/recommendations.service.ts
export class RecommendationsService {
  // Collaborative filtering
  async getPersonalizedRecommendations(userId: string): Promise<Product[]>;

  // Content-based filtering
  async getSimilarProducts(productId: string): Promise<Product[]>;

  // Purchase history based
  async getFrequentlyBoughtTogether(productId: string): Promise<Product[]>;

  // Trending products
  async getTrendingProducts(category?: string): Promise<Product[]>;

  // Recently viewed
  async getRecentlyViewed(userId: string): Promise<Product[]>;
}
```

### 7.4 Notifications

```typescript
// libs/shop/notifications/src/lib/notification.service.ts
interface Notification {
  id: string;
  userId: string;
  type: 'order_update' | 'price_drop' | 'back_in_stock' | 'promotion';
  title: string;
  message: string;
  data?: Record<string, unknown>;
  read: boolean;
  createdAt: Date;
}

// Email notifications
await emailService.send({
  to: user.email,
  template: 'order-shipped',
  data: { orderNumber, trackingUrl },
});

// Push notifications (optional)
await pushService.send(userId, {
  title: 'Order Shipped!',
  body: `Your order #${orderNumber} is on its way.`,
  data: { orderId },
});
```

### 7.5 Implementation Tasks

- [ ] Create wishlist feature
- [ ] Build product reviews system
- [ ] Implement review moderation
- [ ] Add product recommendations
- [ ] Create notification system
- [ ] Build email templates
- [ ] Add price drop alerts
- [ ] Implement back-in-stock alerts

---

## 8. Phase 7: Search & Discovery

### 8.1 Search Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Search Architecture                               │
│                                                                         │
│  ┌──────────┐      ┌──────────────┐      ┌──────────────────┐          │
│  │  Client  │─────▶│   API        │─────▶│  Search Engine   │          │
│  │          │      │              │      │  (Elasticsearch/ │          │
│  │          │      │              │      │   Algolia)       │          │
│  └──────────┘      └──────────────┘      └──────────────────┘          │
│                                                                         │
│  Features:                                                              │
│  - Full-text search                                                    │
│  - Typo tolerance                                                      │
│  - Faceted filtering                                                   │
│  - Autocomplete / suggestions                                          │
│  - Synonyms                                                            │
│  - Relevance tuning                                                    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 8.2 Search Options

#### Option A: Algolia (Recommended for speed-to-market)

| Feature      | Details                                   |
| ------------ | ----------------------------------------- |
| **Service**  | Algolia                                   |
| **Features** | Instant search, typo tolerance, analytics |
| **SDKs**     | react-instantsearch                       |
| **Cost**     | Free tier: 10k searches/month             |

```typescript
// Algolia Integration
import algoliasearch from 'algoliasearch';
import { InstantSearch, SearchBox, Hits, RefinementList } from 'react-instantsearch';

const searchClient = algoliasearch(process.env.ALGOLIA_APP_ID!, process.env.ALGOLIA_SEARCH_KEY!);

export function ProductSearch() {
  return (
    <InstantSearch searchClient={searchClient} indexName="products">
      <SearchBox placeholder="Search products..." />

      <div className="search-layout">
        <aside className="filters">
          <RefinementList attribute="category" />
          <RefinementList attribute="brand" />
          <RangeSlider attribute="price" />
        </aside>

        <main className="results">
          <Hits hitComponent={ProductHit} />
        </main>
      </div>
    </InstantSearch>
  );
}
```

#### Option B: Amazon OpenSearch

| Feature      | Details                          |
| ------------ | -------------------------------- |
| **Service**  | Amazon OpenSearch Service        |
| **Features** | Full Elasticsearch compatibility |
| **Cost**     | ~$20-100/month                   |

#### Option C: PostgreSQL Full-Text Search

| Feature      | Details                     |
| ------------ | --------------------------- |
| **Built-in** | PostgreSQL tsvector/tsquery |
| **Features** | Basic full-text search      |
| **Cost**     | No additional cost          |

```sql
-- PostgreSQL Full-Text Search
CREATE INDEX idx_products_search ON products
USING GIN (to_tsvector('english', name || ' ' || description));

SELECT * FROM products
WHERE to_tsvector('english', name || ' ' || description) @@ plainto_tsquery('english', 'wireless headphones');
```

### 8.3 Implementation Tasks

- [ ] Choose search solution
- [ ] Set up search index
- [ ] Implement product sync
- [ ] Create search UI component
- [ ] Add autocomplete/suggestions
- [ ] Implement faceted filtering
- [ ] Add search analytics
- [ ] Tune relevance

---

## 9. Phase 8: Analytics & Monitoring

### 9.1 Analytics Stack

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Analytics Architecture                            │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Frontend Analytics                            │   │
│  │                                                                  │   │
│  │  - Page views                                                   │   │
│  │  - User interactions                                            │   │
│  │  - Conversion funnel                                            │   │
│  │  - Session recordings (optional)                                │   │
│  │                                                                  │   │
│  │  Tools: Google Analytics 4, Mixpanel, Amplitude                 │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Backend Metrics                               │   │
│  │                                                                  │   │
│  │  - API response times                                           │   │
│  │  - Error rates                                                  │   │
│  │  - Database performance                                         │   │
│  │  - Resource utilization                                         │   │
│  │                                                                  │   │
│  │  Tools: CloudWatch, Datadog, New Relic                          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Business Metrics                              │   │
│  │                                                                  │   │
│  │  - Revenue tracking                                             │   │
│  │  - Cart abandonment                                             │   │
│  │  - Product performance                                          │   │
│  │  - Customer lifetime value                                      │   │
│  │                                                                  │   │
│  │  Dashboard: Metabase, Grafana, Custom                           │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 9.2 E-commerce Events

```typescript
// libs/shop/analytics/src/lib/events.ts
interface AnalyticsEvent {
  event: string;
  properties?: Record<string, unknown>;
}

const ecommerceEvents = {
  // Product Events
  viewProduct: (product: Product) => ({
    event: 'view_item',
    properties: {
      item_id: product.id,
      item_name: product.name,
      item_category: product.category,
      price: product.price,
    },
  }),

  // Cart Events
  addToCart: (product: Product, quantity: number) => ({
    event: 'add_to_cart',
    properties: {
      item_id: product.id,
      item_name: product.name,
      quantity,
      value: product.price * quantity,
    },
  }),

  // Checkout Events
  beginCheckout: (cart: Cart) => ({
    event: 'begin_checkout',
    properties: {
      value: cart.subtotal,
      items: cart.items.map((item) => ({
        item_id: item.productId,
        quantity: item.quantity,
      })),
    },
  }),

  // Purchase Event
  purchase: (order: Order) => ({
    event: 'purchase',
    properties: {
      transaction_id: order.orderNumber,
      value: order.total,
      currency: order.currency,
      tax: order.tax,
      shipping: order.shippingCost,
      items: order.items,
    },
  }),
};
```

### 9.3 Key Metrics Dashboard

| Metric                        | Description                     |
| ----------------------------- | ------------------------------- |
| **Conversion Rate**           | Visitors → Customers            |
| **Average Order Value**       | Total revenue / Orders          |
| **Cart Abandonment Rate**     | Abandoned carts / Total carts   |
| **Customer Acquisition Cost** | Marketing spend / New customers |
| **Customer Lifetime Value**   | Average revenue per customer    |
| **Product Performance**       | Views, add-to-carts, purchases  |

### 9.4 Implementation Tasks

- [ ] Set up Google Analytics 4
- [ ] Implement event tracking
- [ ] Create analytics hook
- [ ] Set up CloudWatch dashboards
- [ ] Implement business metrics
- [ ] Create admin dashboard
- [ ] Add funnel visualization
- [ ] Set up alerts

---

## 10. Phase 9: Additional Microfrontends

### 10.1 New Remote Applications

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Extended Microfrontend Architecture                   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Shell (Host)                                  │   │
│  │                                                                  │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │   │
│  │  │ Products │  │ Product  │  │   Cart   │  │ Checkout │       │   │
│  │  │          │  │ Detail   │  │          │  │          │       │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │   │
│  │                                                                  │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │   │
│  │  │ Account  │  │  Orders  │  │  Search  │  │  Admin   │       │   │
│  │  │          │  │          │  │          │  │          │       │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 10.2 Proposed Microfrontends

| Remote       | Port | Routes       | Owner Team     |
| ------------ | ---- | ------------ | -------------- |
| **cart**     | 4203 | /cart/\*     | Cart Team      |
| **checkout** | 4204 | /checkout/\* | Payments Team  |
| **account**  | 4205 | /account/\*  | Identity Team  |
| **orders**   | 4206 | /orders/\*   | Orders Team    |
| **search**   | 4207 | /search/\*   | Discovery Team |
| **admin**    | 4208 | /admin/\*    | Platform Team  |

### 10.3 Account Microfrontend

```
apps/account/
├── src/
│   ├── app/
│   │   ├── profile/
│   │   │   └── profile-page.tsx
│   │   ├── addresses/
│   │   │   └── addresses-page.tsx
│   │   ├── payment-methods/
│   │   │   └── payment-methods-page.tsx
│   │   └── settings/
│   │       └── settings-page.tsx
│   ├── remote-entry.ts
│   └── main.tsx
├── module-federation.config.ts
└── package.json
```

### 10.4 Admin Microfrontend

```
apps/admin/
├── src/
│   ├── app/
│   │   ├── dashboard/
│   │   │   └── dashboard-page.tsx
│   │   ├── products/
│   │   │   ├── products-list.tsx
│   │   │   └── product-form.tsx
│   │   ├── orders/
│   │   │   ├── orders-list.tsx
│   │   │   └── order-detail.tsx
│   │   ├── customers/
│   │   │   └── customers-list.tsx
│   │   └── settings/
│   │       └── settings-page.tsx
│   ├── remote-entry.ts
│   └── main.tsx
├── module-federation.config.ts
└── package.json
```

### 10.5 Implementation Tasks

- [ ] Generate cart microfrontend
- [ ] Generate checkout microfrontend
- [ ] Generate account microfrontend
- [ ] Generate orders microfrontend
- [ ] Generate admin microfrontend
- [ ] Update shell routing
- [ ] Configure deployment pipelines
- [ ] Set up independent deployments

---

## 11. Phase 10: Advanced Infrastructure

### 11.1 API Gateway

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        API Gateway Architecture                          │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                    Amazon API Gateway                             │  │
│  │                                                                   │  │
│  │  Features:                                                        │  │
│  │  - Rate limiting                                                 │  │
│  │  - Request validation                                            │  │
│  │  - API versioning                                                │  │
│  │  - Usage plans & API keys                                        │  │
│  │  - Request/response transformation                               │  │
│  │  - Caching                                                       │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                    │                                    │
│          ┌─────────────────────────┼─────────────────────────┐         │
│          │                         │                         │          │
│          ▼                         ▼                         ▼          │
│  ┌──────────────┐         ┌──────────────┐         ┌──────────────┐   │
│  │  Products    │         │   Orders     │         │   Users      │   │
│  │  Service     │         │   Service    │         │   Service    │   │
│  └──────────────┘         └──────────────┘         └──────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 11.2 Microservices Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Microservices Architecture                        │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                    Service Mesh (Optional)                        │  │
│  │                    AWS App Mesh / Istio                           │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐       │
│  │  Products  │  │   Orders   │  │  Payments  │  │   Users    │       │
│  │  Service   │  │   Service  │  │  Service   │  │   Service  │       │
│  │            │  │            │  │            │  │            │       │
│  │  - CRUD    │  │  - Create  │  │  - Stripe  │  │  - Auth    │       │
│  │  - Search  │  │  - Status  │  │  - Refunds │  │  - Profile │       │
│  │  - Stock   │  │  - History │  │  - Reports │  │  - Prefs   │       │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘       │
│        │               │               │               │               │
│        └───────────────┴───────────────┴───────────────┘               │
│                                │                                        │
│                                ▼                                        │
│                    ┌────────────────────┐                              │
│                    │   Event Bus        │                              │
│                    │   (Amazon SQS/SNS) │                              │
│                    └────────────────────┘                              │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 11.3 Event-Driven Architecture

```typescript
// Event Types
interface DomainEvent {
  eventType: string;
  aggregateId: string;
  timestamp: Date;
  data: Record<string, unknown>;
}

// Events
const events = {
  OrderCreated: 'order.created',
  OrderPaid: 'order.paid',
  OrderShipped: 'order.shipped',
  StockUpdated: 'inventory.stock_updated',
  UserRegistered: 'user.registered',
  CartAbandoned: 'cart.abandoned',
};

// Event Publisher
class EventPublisher {
  async publish(event: DomainEvent): Promise<void> {
    await snsClient.send(
      new PublishCommand({
        TopicArn: process.env.EVENTS_TOPIC_ARN,
        Message: JSON.stringify(event),
        MessageAttributes: {
          eventType: { DataType: 'String', StringValue: event.eventType },
        },
      })
    );
  }
}

// Event Handler
class OrderEventHandler {
  @Subscribe('order.created')
  async handleOrderCreated(event: DomainEvent): Promise<void> {
    // Send confirmation email
    // Update inventory
    // Notify warehouse
  }
}
```

### 11.4 CI/CD Improvements

```yaml
# Feature flags with LaunchDarkly
- name: Deploy with feature flags
  run: |
    npx nx build shell --configuration=production
    launchdarkly-ci update-flags --env production

# Canary deployments
- name: Canary release
  run: |
    # Deploy to 10% of traffic
    aws apprunner update-service \
      --service-arn $SERVICE_ARN \
      --traffic-routing-configuration '{"percentage": 10}'

    # Monitor metrics
    sleep 300

    # If successful, roll out to 100%
    aws apprunner update-service \
      --service-arn $SERVICE_ARN \
      --traffic-routing-configuration '{"percentage": 100}'
```

### 11.5 Implementation Tasks

- [ ] Set up Amazon API Gateway
- [ ] Implement rate limiting
- [ ] Add request validation
- [ ] Create microservices structure
- [ ] Set up event bus (SQS/SNS)
- [ ] Implement event handlers
- [ ] Add feature flags
- [ ] Implement canary deployments
- [ ] Set up blue/green deployments

---

## 12. Implementation Priority Matrix

### 12.1 Priority Levels

| Priority        | Criteria                                    |
| --------------- | ------------------------------------------- |
| 🔴 **Critical** | Required for basic e-commerce functionality |
| 🟡 **High**     | Important for user experience & business    |
| 🟢 **Medium**   | Enhances platform capabilities              |
| 🔵 **Low**      | Nice-to-have features                       |

### 12.2 Implementation Roadmap

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Implementation Timeline                           │
│                                                                         │
│  Phase 1-2 (Critical)                                                   │
│  ────────────────────                                                   │
│  ├── Database Integration        🔴 Critical                            │
│  ├── User Authentication         🔴 Critical                            │
│  └── Basic Authorization         🔴 Critical                            │
│                                                                         │
│  Phase 3-4 (Critical)                                                   │
│  ────────────────────                                                   │
│  ├── Shopping Cart               🔴 Critical                            │
│  ├── Checkout Flow               🔴 Critical                            │
│  └── Order Management            🟡 High                                │
│                                                                         │
│  Phase 5-6 (High)                                                       │
│  ────────────────                                                       │
│  ├── Payment Processing          🟡 High                                │
│  ├── User Profiles               🟡 High                                │
│  ├── Wishlist                    🟡 High                                │
│  └── Reviews                     🟡 High                                │
│                                                                         │
│  Phase 7-8 (Medium)                                                     │
│  ─────────────────                                                      │
│  ├── Advanced Search             🟢 Medium                              │
│  ├── Recommendations             🟢 Medium                              │
│  └── Analytics                   🟢 Medium                              │
│                                                                         │
│  Phase 9-10 (Medium-Low)                                                │
│  ──────────────────────                                                 │
│  ├── Additional Microfrontends   🟢 Medium                              │
│  ├── API Gateway                 🟢 Medium                              │
│  ├── Microservices               🔵 Low                                 │
│  └── Event-Driven Architecture   🔵 Low                                 │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 12.3 Dependency Graph

```
Database ──────┬──▶ Authentication ──▶ Shopping Cart ──▶ Checkout
               │
               ├──▶ Order Management ──▶ Payment Processing
               │
               └──▶ User Profiles ──▶ Wishlist ──▶ Reviews

Search ──▶ Recommendations

Analytics (can run in parallel)

Microfrontends (can run in parallel after core features)
```

---

## 13. Architecture Evolution

### 13.1 Current vs Target Architecture

| Aspect       | Current        | Target                 |
| ------------ | -------------- | ---------------------- |
| **Data**     | In-memory      | PostgreSQL + Redis     |
| **Auth**     | None           | Cognito + JWT          |
| **Cart**     | None           | Persistent + Guest     |
| **Payments** | None           | Stripe integration     |
| **Search**   | Basic filter   | Algolia/Elasticsearch  |
| **API**      | Single service | API Gateway + Services |
| **Events**   | Synchronous    | Event-driven (SQS/SNS) |

### 13.2 Target Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Target Architecture                                   │
│                                                                             │
│                              ┌──────────────┐                               │
│                              │   Route 53   │                               │
│                              └──────┬───────┘                               │
│                                     │                                       │
│            ┌────────────────────────┼────────────────────────┐             │
│            │                        │                        │              │
│            ▼                        ▼                        ▼              │
│   ┌────────────────┐      ┌────────────────┐      ┌────────────────┐       │
│   │   CloudFront   │      │  API Gateway   │      │    Cognito     │       │
│   │   (Frontend)   │      │                │      │    (Auth)      │       │
│   └───────┬────────┘      └───────┬────────┘      └────────────────┘       │
│           │                       │                                         │
│   ┌───────┴───────┐               │                                         │
│   │               │               │                                         │
│   ▼               ▼               ▼                                         │
│ ┌─────┐        ┌─────┐      ┌──────────────────────────────────────┐       │
│ │ S3  │        │ S3  │      │           App Runner Services         │       │
│ │Shell│        │MFEs │      │                                       │       │
│ └─────┘        └─────┘      │  ┌─────────┐  ┌─────────┐  ┌───────┐ │       │
│                             │  │Products │  │ Orders  │  │ Users │ │       │
│                             │  └─────────┘  └─────────┘  └───────┘ │       │
│                             └──────────────────┬───────────────────┘       │
│                                                │                            │
│                    ┌───────────────────────────┼───────────────────────┐   │
│                    │                           │                       │    │
│                    ▼                           ▼                       ▼    │
│           ┌────────────────┐          ┌────────────────┐      ┌──────────┐ │
│           │   PostgreSQL   │          │     Redis      │      │    S3    │ │
│           │   (RDS)        │          │ (ElastiCache)  │      │ (Images) │ │
│           └────────────────┘          └────────────────┘      └──────────┘ │
│                    │                                                        │
│                    ▼                                                        │
│           ┌────────────────┐                                               │
│           │   SQS/SNS      │                                               │
│           │  (Events)      │                                               │
│           └────────────────┘                                               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Appendix

### A. Library Dependencies

```
New Libraries to Create:
├── libs/shop/auth/           # Authentication context & hooks
├── libs/shop/cart/           # Cart context & components
├── libs/shop/checkout/       # Checkout flow components
├── libs/shop/wishlist/       # Wishlist feature
├── libs/shop/reviews/        # Product reviews
├── libs/shop/notifications/  # Notifications system
├── libs/shop/analytics/      # Analytics tracking
├── libs/api/auth/            # Auth middleware
├── libs/api/orders/          # Orders service
├── libs/api/payments/        # Payment processing
├── libs/api/notifications/   # Email/push notifications
└── libs/shared/events/       # Event types & handlers
```

### B. Environment Variables

```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/ecommerce
REDIS_URL=redis://host:6379

# Authentication
COGNITO_USER_POOL_ID=us-east-1_xxxxx
COGNITO_CLIENT_ID=xxxxxxxxx
COGNITO_DOMAIN=auth.ecommerce.veeracs.info

# Payments
STRIPE_SECRET_KEY=sk_xxx
STRIPE_PUBLISHABLE_KEY=pk_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# Search
ALGOLIA_APP_ID=xxxxx
ALGOLIA_ADMIN_KEY=xxxxx
ALGOLIA_SEARCH_KEY=xxxxx

# Analytics
GA_MEASUREMENT_ID=G-xxxxxxxxxx

# Email
SENDGRID_API_KEY=SG.xxxxx
FROM_EMAIL=orders@ecommerce.veeracs.info
```

### C. Related Documentation

| Document                                                   | Description                 |
| ---------------------------------------------------------- | --------------------------- |
| [SYSTEM_DESIGN.md](./SYSTEM_DESIGN.md)                     | Current system architecture |
| [TECH_STACK.md](./TECH_STACK.md)                           | Technology stack details    |
| [AWS_DEPLOYMENT.md](./AWS_DEPLOYMENT.md)                   | Deployment guide            |
| [MODULE_FEDERATION_GUIDE.md](./MODULE_FEDERATION_GUIDE.md) | MFE best practices          |

---

**Document Owner:** Platform Team  
**Review Cycle:** Quarterly  
**Next Review:** April 2026
