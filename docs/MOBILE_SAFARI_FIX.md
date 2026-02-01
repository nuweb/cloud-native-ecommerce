# Mobile Safari Fix Guide

## Problem

The ecommerce.veeracs.info site is not loading on mobile Safari (iPhone), while the portfolio site (veeracs.info) loads correctly.

## Root Causes

Mobile Safari has stricter requirements than desktop browsers for:

1. **CORS headers** on dynamically loaded JavaScript modules (Module Federation)
2. **Content-Type headers** for JavaScript files
3. **Error handling** in module loading
4. **Cache behavior** for dynamic imports

## Fixes Required

### Fix 1: Add CORS Headers to CloudFront

The Module Federation remoteEntry.js files need proper CORS headers.

**Update `infra/main.tf`** - Add response headers policy:

```hcl
# =============================================================================
# CloudFront Response Headers Policy for CORS
# =============================================================================

resource "aws_cloudfront_response_headers_policy" "cors_policy" {
  name    = "${var.project_name}-cors-policy"
  comment = "CORS policy for Module Federation"

  cors_config {
    access_control_allow_credentials = false

    access_control_allow_headers {
      items = ["*"]
    }

    access_control_allow_methods {
      items = ["GET", "HEAD", "OPTIONS"]
    }

    access_control_allow_origins {
      items = ["*"]
    }

    access_control_max_age_sec = 3600

    origin_override = true
  }

  custom_headers_config {
    items {
      header   = "X-Content-Type-Options"
      override = true
      value    = "nosniff"
    }
  }
}
```

**Update all cache behaviors** in the CloudFront distribution to use the policy:

```hcl
# Default behavior - Shell (Host)
default_cache_behavior {
  allowed_methods        = ["GET", "HEAD", "OPTIONS"]
  cached_methods         = ["GET", "HEAD"]
  target_origin_id       = "shell"
  viewer_protocol_policy = "redirect-to-https"
  compress               = true

  # Add this line:
  response_headers_policy_id = aws_cloudfront_response_headers_policy.cors_policy.id

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

  # Add this line:
  response_headers_policy_id = aws_cloudfront_response_headers_policy.cors_policy.id

  forwarded_values {
    query_string = false
    cookies {
      forward = "none"
    }
  }

  min_ttl     = 0
  default_ttl = 86400
  max_ttl     = 31536000
}

# Product-Detail Remote behavior
ordered_cache_behavior {
  path_pattern           = "/remotes/product-detail/*"
  allowed_methods        = ["GET", "HEAD", "OPTIONS"]
  cached_methods         = ["GET", "HEAD"]
  target_origin_id       = "product-detail"
  viewer_protocol_policy = "redirect-to-https"
  compress               = true

  # Add this line:
  response_headers_policy_id = aws_cloudfront_response_headers_policy.cors_policy.id

  forwarded_values {
    query_string = false
    cookies {
      forward = "none"
    }
  }

  min_ttl     = 0
  default_ttl = 86400
  max_ttl     = 31536000
}
```

---

### Fix 2: Update S3 Upload Content-Types

Ensure JavaScript files have correct MIME types when uploaded to S3.

**Update `.github/workflows/deploy.yml`**:

```yaml
- name: Deploy Shell to S3
  run: |
    # Upload JS files with correct Content-Type
    aws s3 sync dist/shell s3://cloud-native-ecommerce-shell-production \
      --delete \
      --exclude "*.html" \
      --exclude "*.json" \
      --content-type "application/javascript" \
      --cache-control "public, max-age=31536000, immutable"

    # Upload HTML with no cache
    aws s3 cp dist/shell/index.html s3://cloud-native-ecommerce-shell-production/index.html \
      --content-type "text/html" \
      --cache-control "public, max-age=0, must-revalidate"

- name: Deploy Products to S3
  run: |
    aws s3 sync dist/products s3://cloud-native-ecommerce-products-production/remotes/products \
      --delete \
      --exclude "*.html" \
      --exclude "*.json" \
      --content-type "application/javascript" \
      --cache-control "public, max-age=31536000, immutable"

- name: Deploy Product-Detail to S3
  run: |
    aws s3 sync dist/product-detail s3://cloud-native-ecommerce-product-detail-production/remotes/product-detail \
      --delete \
      --exclude "*.html" \
      --exclude "*.json" \
      --content-type "application/javascript" \
      --cache-control "public, max-age=31536000, immutable"
```

---

### Fix 3: Add Error Boundary for Remote Loading

Mobile Safari needs better error handling for failed module loads.

**Create `apps/shell/src/app/ErrorBoundary.tsx`**:

```tsx
import { Component, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: any) {
    console.error('ErrorBoundary caught:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        this.props.fallback || (
          <div
            style={{
              padding: '20px',
              textAlign: 'center',
              color: '#721c24',
              backgroundColor: '#f8d7da',
              border: '1px solid #f5c6cb',
              borderRadius: '4px',
              margin: '20px',
            }}
          >
            <h2>Something went wrong</h2>
            <p>Please try refreshing the page.</p>
            {this.state.error && (
              <details style={{ marginTop: '10px' }}>
                <summary>Error details</summary>
                <pre
                  style={{
                    textAlign: 'left',
                    fontSize: '12px',
                    overflow: 'auto',
                  }}
                >
                  {this.state.error.message}
                </pre>
              </details>
            )}
          </div>
        )
      );
    }

    return this.props.children;
  }
}
```

**Update `apps/shell/src/app/app.tsx`**:

```tsx
import { lazy, Suspense } from 'react';
import { Route, Routes, Navigate } from 'react-router-dom';
import { LoadingSpinner } from '@org/shop-shared-ui';
import { ErrorBoundary } from './ErrorBoundary';
import logo from '../assets/nucart-logo.svg';
import './app.css';

// Federated remotes - loaded at runtime from remote apps
const ProductList = lazy(() =>
  import('products/Module')
    .then((m) => ({ default: m.default }))
    .catch((err) => {
      console.error('Failed to load products module:', err);
      throw err;
    })
);

const ProductDetail = lazy(() =>
  import('product-detail/Module')
    .then((m) => ({ default: m.default }))
    .catch((err) => {
      console.error('Failed to load product-detail module:', err);
      throw err;
    })
);

export function App() {
  return (
    <ErrorBoundary>
      <div className="app">
        <header className="app-header">
          <div className="header-content">
            <img src={logo} alt="NuCart Logo" className="app-logo" />
          </div>
        </header>

        <main className="app-main">
          <Suspense fallback={<LoadingSpinner />}>
            <Routes>
              <Route path="/" element={<Navigate to="/products" replace />} />
              <Route
                path="/products"
                element={
                  <ErrorBoundary fallback={<div>Failed to load products</div>}>
                    <ProductList />
                  </ErrorBoundary>
                }
              />
              <Route
                path="/products/:id"
                element={
                  <ErrorBoundary fallback={<div>Failed to load product detail</div>}>
                    <ProductDetail />
                  </ErrorBoundary>
                }
              />
              <Route path="*" element={<Navigate to="/products" replace />} />
            </Routes>
          </Suspense>
        </main>
      </div>
    </ErrorBoundary>
  );
}

export default App;
```

---

### Fix 4: Add Custom Error Page for CloudFront

Add a custom 403/404 error page so users see a helpful message instead of blank screen.

**Create `apps/shell/public/error.html`**:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Error - Nx Shop Demo</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      background: #f5f5f5;
    }
    .error-container {
      text-align: center;
      padding: 40px;
      background: white;
      border-radius: 8px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
      max-width: 500px;
    }
    h1 { color: #d32f2f; }
    button {
      margin-top: 20px;
      padding: 10px 20px;
      background: #1976d2;
      color: white;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-size: 16px;
    }
    button:hover { background: #1565c0; }
  </style>
</head>
<body>
  <div class="error-container">
    <h1>Oops! Something went wrong</h1>
    <p>We're having trouble loading the page.</p>
    <button onclick="window.location.reload()">Reload Page</button>
    <p style="margin-top: 20px; font-size: 14px; color: #666;">
      If the problem persists, please try:
      <ul style="text-align: left; margin-top: 10px;">
        <li>Clearing your browser cache</li>
        <li>Using a different browser</li>
        <li>Checking your internet connection</li>
      </ul>
    </p>
  </div>
</body>
</html>
```

**Update CloudFront custom error responses in `infra/main.tf`**:

```hcl
resource "aws_cloudfront_distribution" "main" {
  # ... existing configuration ...

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/error.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  # ... rest of configuration ...
}
```

---

### Fix 5: Update Webpack Configuration for Safari Compatibility

Ensure the webpack build output is Safari-compatible.

**Update `apps/shell/webpack.config.ts`**:

```typescript
import { composePlugins, withNx } from '@nx/webpack';
import { withReact } from '@nx/react';
import { withModuleFederation } from '@nx/module-federation/webpack';
import { ModuleFederationConfig, Remotes } from '@nx/module-federation';

const isProd = process.env['NODE_ENV'] === 'production';
const PROD_DOMAIN = process.env['PROD_DOMAIN'] || 'https://ecommerce.veeracs.info';

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
  shared: {
    react: {
      singleton: true,
      requiredVersion: false,
      eager: false,
    },
    'react-dom': {
      singleton: true,
      requiredVersion: false,
      eager: false,
    },
    'react-router-dom': {
      singleton: true,
      requiredVersion: false,
      eager: false,
    },
  },
};

export default composePlugins(
  withNx(),
  withReact(),
  withModuleFederation(config, { dts: false }),
  (config) => {
    // Ensure Safari-compatible output
    if (config.output) {
      config.output.chunkLoadingGlobal = 'webpackChunkshell';
      config.output.uniqueName = 'shell';
    }

    // Ensure proper target for Safari
    config.target = 'web';

    return config;
  }
);
```

---

## Deployment Steps

1. **Update Terraform infrastructure**:

   ```bash
   cd infra
   terraform apply
   ```

2. **Update application code** (ErrorBoundary, webpack config)

3. **Commit and push** to trigger GitHub Actions:

   ```bash
   git add -A
   git commit -m "Fix mobile Safari compatibility"
   git push origin main
   ```

4. **Manual invalidation** (if needed):

   ```bash
   aws cloudfront create-invalidation \
     --distribution-id YOUR_DIST_ID \
     --paths "/*"
   ```

5. **Test on mobile Safari**:
   - Clear Safari cache
   - Open https://ecommerce.veeracs.info
   - Check browser console for errors

---

## Debugging on Mobile Safari

### Enable Safari Web Inspector

1. On iPhone: Settings → Safari → Advanced → Web Inspector (ON)
2. On Mac: Safari → Develop → [Your iPhone] → [Your Site]

### Check for Common Errors

Look for these errors in the console:

- `Failed to load module script: Expected a JavaScript module script`

  - **Fix**: Content-Type headers (Fix 2)

- `CORS policy: No 'Access-Control-Allow-Origin' header`

  - **Fix**: CloudFront CORS headers (Fix 1)

- `Unhandled Promise Rejection: ChunkLoadError`
  - **Fix**: Error boundaries (Fix 3)

---

## Verification Checklist

After deployment, verify:

- [ ] Site loads on desktop Safari
- [ ] Site loads on mobile Safari (iPhone)
- [ ] Remote modules load correctly
- [ ] Navigation between routes works
- [ ] Console shows no CORS errors
- [ ] Network tab shows 200 responses for remoteEntry.js files
- [ ] Content-Type headers are `application/javascript` for JS files

---

## Additional Resources

- [Module Federation Safari Issues](https://github.com/module-federation/module-federation-examples/issues?q=safari)
- [CloudFront CORS Configuration](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/header-caching.html)
- [Safari Web Inspector Guide](https://developer.apple.com/safari/tools/)
