# Module Federation Guide

This document covers best practices for working with Module Federation in a microfrontend architecture, including independent team deployments.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [How Module Federation Works](#how-module-federation-works)
- [Independent Team Deployment](#independent-team-deployment)
- [Shared Dependencies](#shared-dependencies)
- [Versioning Strategies](#versioning-strategies)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

**Module Federation** is a Webpack 5 feature that allows JavaScript applications to dynamically load code from other applications at runtime. This enables:

- **Independent deployments** - Teams deploy without coordinating
- **Technology flexibility** - Different frameworks per remote (with caveats)
- **Faster builds** - Only build what changed
- **Team autonomy** - Own your code end-to-end

### Current Architecture

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

---

## Architecture

### Host vs Remote

| Concept | Description | Example |
|---------|-------------|---------|
| **Host (Shell)** | Application that consumes remote modules | `apps/shell` |
| **Remote** | Application that exposes modules | `apps/products`, `apps/product-detail` |
| **Exposed Module** | Code that a remote shares | `./Module` → `remote-entry.ts` |
| **Remote Entry** | Generated file listing exposed modules | `remoteEntry.js` |

### File Structure

```
apps/
├── shell/                          # HOST
│   ├── src/
│   │   ├── app/app.tsx             # Imports remotes
│   │   └── remotes.d.ts            # Type declarations
│   ├── module-federation.config.ts # Remote URLs
│   └── webpack.config.ts           # MFE setup
│
├── products/                       # REMOTE
│   ├── src/
│   │   ├── app/app.tsx             # Standalone app
│   │   └── remote-entry.ts         # Exposed module
│   ├── module-federation.config.ts # Exposes config
│   └── webpack.config.ts           # MFE setup
│
└── product-detail/                 # REMOTE
    └── ... (same structure)
```

---

## How Module Federation Works

### 1. Remote Exposes a Module

```typescript
// apps/products/module-federation.config.ts
const config: ModuleFederationConfig = {
  name: 'products',
  exposes: {
    './Module': './src/remote-entry.ts',  // Key: what shell imports
  },
};
```

```typescript
// apps/products/src/remote-entry.ts
import { ProductList } from '@org/shop-feature-products';
export default ProductList;
```

### 2. Host Declares Remotes

```typescript
// apps/shell/module-federation.config.ts (development)
const config: ModuleFederationConfig = {
  name: 'shell',
  remotes: [
    ['products', 'http://localhost:4201/'],
    ['product-detail', 'http://localhost:4202/'],
  ],
};
```

```typescript
// apps/shell/webpack.config.ts (production)
const prodRemotes: Remotes = [
  ['products', `${PROD_DOMAIN}/remotes/products/remoteEntry.js`],
  ['product-detail', `${PROD_DOMAIN}/remotes/product-detail/remoteEntry.js`],
];
```

### 3. Host Loads Remote at Runtime

```tsx
// apps/shell/src/app/app.tsx
import { lazy, Suspense } from 'react';

// These are loaded at RUNTIME from remote URLs
const ProductList = lazy(() => import('products/Module'));
const ProductDetail = lazy(() => import('product-detail/Module'));

export function App() {
  return (
    <Suspense fallback={<Loading />}>
      <Routes>
        <Route path="/products" element={<ProductList />} />
        <Route path="/products/:id" element={<ProductDetail />} />
      </Routes>
    </Suspense>
  );
}
```

### 4. Type Declarations

```typescript
// apps/shell/src/remotes.d.ts
declare module 'products/Module' {
  const ProductList: React.ComponentType;
  export default ProductList;
}

declare module 'product-detail/Module' {
  const ProductDetail: React.ComponentType;
  export default ProductDetail;
}
```

---

## Independent Team Deployment

### Deployment Models

#### Model 1: Single Repo, Separate Workflows (Recommended for Small Teams)

```
.github/workflows/
├── deploy-shell.yml           # Triggers on shell changes
├── deploy-products.yml        # Triggers on products changes
├── deploy-product-detail.yml  # Triggers on product-detail changes
└── deploy-api.yml             # Triggers on API changes
```

**Example: `deploy-products.yml`**

```yaml
name: Deploy Products Remote

on:
  push:
    branches: [main]
    paths:
      - 'apps/products/**'
      - 'libs/shop/feature-products/**'
      - 'libs/shop/shared-ui/**'
      - 'libs/shop/data/**'
      - 'libs/shared/models/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
        with:
          version: 8
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          
      - run: pnpm install
      
      - name: Build Products
        run: npx nx build products --configuration=production
        env:
          NODE_ENV: production
          
      - name: Configure AWS
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
          
      - name: Deploy to S3
        run: |
          aws s3 sync dist/products \
            s3://cloud-native-ecommerce-products-production/remotes/products \
            --delete \
            --cache-control "public, max-age=31536000, immutable" \
            --exclude "*.html" --exclude "*.json"
          
          # HTML and JSON with shorter cache
          aws s3 sync dist/products \
            s3://cloud-native-ecommerce-products-production/remotes/products \
            --exclude "*" --include "*.html" --include "*.json" \
            --cache-control "public, max-age=0, must-revalidate"
            
      - name: Invalidate CloudFront
        run: |
          aws cloudfront create-invalidation \
            --distribution-id ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }} \
            --paths "/remotes/products/*"
```

#### Model 2: Separate Repositories (Large Organizations)

```
Organization Repos:
├── ecommerce-shell/           # Team A
├── ecommerce-products/        # Team B
├── ecommerce-product-detail/  # Team C
├── ecommerce-api/             # Team D
└── ecommerce-shared/          # Platform Team (published to npm)
```

**Shared libs as npm packages:**

```json
// ecommerce-products/package.json
{
  "dependencies": {
    "@company/shop-shared-ui": "^1.2.0",
    "@company/shop-data": "^1.2.0",
    "@company/models": "^1.0.0"
  }
}
```

#### Model 3: Versioned Deployments (Advanced)

Store multiple versions for rollback capability:

```
S3 Bucket Structure:
remotes/
├── products/
│   ├── latest/
│   │   └── remoteEntry.js
│   ├── v1.2.3/
│   │   └── remoteEntry.js
│   └── v1.2.2/
│       └── remoteEntry.js
```

**Shell loads specific version:**

```typescript
// Can be controlled via environment variable or feature flag
const PRODUCTS_VERSION = process.env.PRODUCTS_VERSION || 'latest';
const prodRemotes: Remotes = [
  ['products', `${PROD_DOMAIN}/remotes/products/${PRODUCTS_VERSION}/remoteEntry.js`],
];
```

---

## Shared Dependencies

### Why Share Dependencies?

Without sharing, each remote bundles its own React, causing:
- Larger bundle sizes
- Multiple React instances (breaks hooks)
- Inconsistent behavior

### Configuration

```typescript
// Handled automatically by @nx/module-federation
// In webpack.config.ts, shared deps are configured:

shared: {
  react: { singleton: true, requiredVersion: '^19.0.0' },
  'react-dom': { singleton: true, requiredVersion: '^19.0.0' },
  'react-router-dom': { singleton: true, requiredVersion: '^6.0.0' },
}
```

### Rules for Shared Dependencies

| Rule | Reason |
|------|--------|
| **Singleton** | Only one instance (React, Router) |
| **Version alignment** | All apps must use compatible versions |
| **Eager loading** | Host should load shared deps first |

---

## Versioning Strategies

### Semantic Versioning for Remotes

```
MAJOR.MINOR.PATCH

MAJOR - Breaking changes to exposed API
MINOR - New features, backward compatible
PATCH - Bug fixes
```

### Contract Versioning

The "contract" between host and remote is:
1. **Module name** - `products/Module`
2. **Export shape** - `export default ProductList`
3. **Props interface** - What the component accepts

**Breaking Change Example:**

```typescript
// v1.0.0 - Original
export default function ProductList() { ... }

// v2.0.0 - BREAKING: Now requires props
export default function ProductList({ category }: { category: string }) { ... }
```

### Backward Compatibility

```typescript
// Make props optional to maintain compatibility
interface ProductListProps {
  category?: string;  // Optional = backward compatible
}

export default function ProductList({ category }: ProductListProps) {
  // Default behavior if category not provided
}
```

---

## Error Handling

### Graceful Degradation

```tsx
// apps/shell/src/app/app.tsx
import { lazy, Suspense } from 'react';
import { ErrorBoundary } from 'react-error-boundary';

const ProductList = lazy(() => import('products/Module'));

function RemoteError({ error }: { error: Error }) {
  return (
    <div className="error-container">
      <h2>Unable to load products</h2>
      <p>Please try refreshing the page.</p>
      <details>
        <summary>Error details</summary>
        <pre>{error.message}</pre>
      </details>
    </div>
  );
}

export function App() {
  return (
    <ErrorBoundary FallbackComponent={RemoteError}>
      <Suspense fallback={<LoadingSpinner />}>
        <Routes>
          <Route path="/products" element={<ProductList />} />
        </Routes>
      </Suspense>
    </ErrorBoundary>
  );
}
```

### Retry Logic

```typescript
// Retry loading failed remote
const loadRemoteWithRetry = async (
  importFn: () => Promise<any>,
  retries = 3
): Promise<any> => {
  for (let i = 0; i < retries; i++) {
    try {
      return await importFn();
    } catch (error) {
      if (i === retries - 1) throw error;
      await new Promise(r => setTimeout(r, 1000 * (i + 1)));
    }
  }
};

const ProductList = lazy(() => 
  loadRemoteWithRetry(() => import('products/Module'))
);
```

---

## Best Practices

### Do's

| Practice | Reason |
|----------|--------|
| **Keep remotes small** | Faster loads, easier maintenance |
| **Share only necessary deps** | Avoid bloat |
| **Use TypeScript** | Catch contract mismatches early |
| **Version your remotes** | Enable rollbacks |
| **Test in isolation** | Each remote should work standalone |
| **Monitor remote load times** | Performance visibility |
| **Use error boundaries** | Graceful degradation |

### Don'ts

| Anti-Pattern | Problem |
|--------------|---------|
| **Circular dependencies** | Host imports remote that imports host |
| **Tight coupling** | Remotes depending on host internals |
| **Unversioned shared deps** | Version mismatches at runtime |
| **No fallback UI** | Broken page if remote fails |
| **Deploying all together** | Defeats the purpose of MFE |

### Communication Between Remotes

```typescript
// Option 1: URL Parameters
// Shell passes data via route params
<Route path="/products/:id" element={<ProductDetail />} />

// Option 2: Custom Events
// Remote emits event
window.dispatchEvent(new CustomEvent('product-selected', { detail: { id: '123' } }));

// Shell listens
window.addEventListener('product-selected', (e) => navigate(`/products/${e.detail.id}`));

// Option 3: Shared State (Context in Shell)
// Shell provides context, remotes consume
<ShopContext.Provider value={{ cart, addToCart }}>
  <ProductList />
</ShopContext.Provider>
```

---

## Troubleshooting

### Common Errors

#### "Failed to load script resources" (RUNTIME-008)

**Cause:** Remote's `remoteEntry.js` not accessible

**Solutions:**
1. Check remote is deployed to correct URL
2. Verify CORS headers on S3/CloudFront
3. Check CloudFront cache invalidation
4. Verify `remoteEntry.js` exists at expected path

#### "Shared module not found"

**Cause:** Version mismatch in shared dependencies

**Solutions:**
1. Align dependency versions across all apps
2. Check `singleton: true` for React
3. Run `pnpm install` to sync lockfile

#### "Invalid hook call"

**Cause:** Multiple React instances

**Solutions:**
1. Ensure React is shared with `singleton: true`
2. Check all apps use same React version
3. Verify shared config in webpack

### Debugging Commands

```bash
# Check what's exposed by a remote
curl https://ecommerce.veeracs.info/remotes/products/remoteEntry.js | head -50

# Verify S3 contents
aws s3 ls s3://cloud-native-ecommerce-products-production/remotes/products/

# Check CloudFront cache status
curl -I https://ecommerce.veeracs.info/remotes/products/remoteEntry.js

# View Nx dependency graph
npx nx graph
```

---

## Deployment Checklist

### Before Deploying a Remote

- [ ] Tests pass locally
- [ ] Build succeeds with production config
- [ ] No breaking changes to exposed module API
- [ ] Shared dependency versions aligned
- [ ] Error boundary in place (host)

### After Deploying

- [ ] CloudFront cache invalidated
- [ ] Verify remote loads in production
- [ ] Check browser console for errors
- [ ] Monitor error tracking (if configured)
- [ ] Verify analytics/metrics (if configured)

---

## Related Documentation

- [NX_STRUCTURE.md](./NX_STRUCTURE.md) - Monorepo structure
- [TECH_STACK.md](./TECH_STACK.md) - Technology overview
- [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - AWS deployment steps
- [Nx Module Federation Docs](https://nx.dev/concepts/module-federation/module-federation-and-nx)
