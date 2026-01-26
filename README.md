# Cloud-Native E-Commerce Platform

<a alt="Nx logo" href="https://nx.dev" target="_blank" rel="noreferrer"><img src="https://raw.githubusercontent.com/nrwl/nx/master/images/nx-logo.png" width="45"></a>

A production-ready **React Microfrontend E-Commerce Platform** built with [Nx](https://nx.dev) and **Module Federation**.

## Table of Contents

- [Application Overview](#-application-overview)
- [Architecture](#-architecture)
- [Quick Start](#-quick-start)
- [Project Structure](#-project-structure)
- [Module Federation Setup](#-module-federation-setup)
- [TypeScript Configuration](#-typescript-configuration)
- [Development Workflow](#-development-workflow)
- [Available Commands](#-available-commands)
- [Troubleshooting](#-troubleshooting)

---

## Application Overview

This platform demonstrates a **cloud-native microfrontend architecture** for an e-commerce application featuring:

### Features

- **Product Catalog** - Browse products with search, filtering by category, and stock status
- **Product Details** - View detailed product information with images, ratings, and descriptions
- **Responsive Design** - Modern UI that works across all device sizes
- **API Backend** - Express.js API serving product data

### Technology Stack

| Layer | Technology |
|-------|------------|
| **Frontend Framework** | React 19 |
| **Build System** | Nx 22.4 |
| **Module Federation** | Webpack 5 + @nx/module-federation |
| **Routing** | React Router v6 |
| **Styling** | CSS Modules |
| **Backend** | Express.js |
| **Testing** | Vitest (unit), Playwright (e2e) |
| **Package Manager** | pnpm |
| **TypeScript** | TypeScript 5.x |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Shell (Host) - Port 4200                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │  React Router + Suspense + Lazy Loading                         ││
│  │                                                                 ││
│  │  ┌─────────────────────┐    ┌─────────────────────────────────┐││
│  │  │  Products Remote    │    │  Product-Detail Remote          │││
│  │  │  (Port 4201)        │    │  (Port 4202)                    │││
│  │  │                     │    │                                 │││
│  │  │  /products          │    │  /products/:id                  │││
│  │  │  ProductList        │    │  ProductDetail                  │││
│  │  └─────────────────────┘    └─────────────────────────────────┘││
│  └─────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │      API Server (Port 3333)   │
                    │  - GET /api/products          │
                    │  - GET /api/products/:id      │
                    │  - GET /api/products/categories│
                    └───────────────────────────────┘
```

### Applications

| App | Description | Port |
|-----|-------------|------|
| `shell` | Module Federation host - main entry point | 4200 |
| `products` | Remote microfrontend - product listing | 4201 |
| `product-detail` | Remote microfrontend - product details | 4202 |
| `api` | Express.js backend API | 3333 |
| `shop` | Standalone Vite app (alternative) | 4200 |

### Libraries

| Library | Scope | Type | Description |
|---------|-------|------|-------------|
| `@org/shop-feature-products` | shop | feature | Product listing component |
| `@org/shop-feature-product-detail` | shop | feature | Product detail component |
| `@org/shop-data` | shop | data | Data fetching hooks and services |
| `@org/shop-shared-ui` | shop | ui | Shared UI components (LoadingSpinner, ProductCard, etc.) |
| `@org/models` | shared | data | TypeScript interfaces and types |
| `@org/api-products` | api | feature | Products service for API |
| `@org/test-utils` | shared | util | Testing utilities |

---

## Quick Start

### Prerequisites

- **Node.js** >= 20.x
- **pnpm** >= 8.x (recommended) or npm

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd cloud-native-ecommerce

# Install dependencies
pnpm install

# Start the full application (shell + remotes + API)
npx nx serve shell
```

### Access the Application

| Service | URL |
|---------|-----|
| **Main Application** | http://localhost:4200 |
| **Products Remote** | http://localhost:4201 |
| **Product Detail Remote** | http://localhost:4202 |
| **API Server** | http://localhost:3333 |

---

## Project Structure

```
cloud-native-ecommerce/
├── apps/
│   ├── shell/                    # Module Federation Host
│   │   ├── src/
│   │   │   ├── app/
│   │   │   │   └── app.tsx       # Main app with routing
│   │   │   ├── bootstrap.tsx     # React entry point
│   │   │   ├── main.tsx          # Webpack entry
│   │   │   └── remotes.d.ts      # Remote type declarations
│   │   ├── module-federation.config.ts
│   │   ├── webpack.config.ts
│   │   ├── .babelrc
│   │   └── package.json
│   │
│   ├── products/                 # Products Remote
│   │   ├── src/
│   │   │   ├── app/app.tsx
│   │   │   ├── remote-entry.ts   # Federation entry point
│   │   │   └── bootstrap.tsx
│   │   ├── module-federation.config.ts
│   │   ├── webpack.config.ts
│   │   ├── .babelrc
│   │   └── package.json
│   │
│   ├── product-detail/           # Product Detail Remote
│   │   ├── src/
│   │   │   ├── app/app.tsx
│   │   │   ├── remote-entry.ts
│   │   │   └── bootstrap.tsx
│   │   ├── module-federation.config.ts
│   │   ├── webpack.config.ts
│   │   ├── .babelrc
│   │   └── package.json
│   │
│   ├── api/                      # Backend API
│   │   ├── src/main.ts
│   │   └── package.json
│   │
│   ├── shop/                     # Standalone Vite App
│   │   └── ...
│   │
│   └── shop-e2e/                 # E2E Tests
│       └── ...
│
├── libs/
│   ├── shop/
│   │   ├── feature-products/     # Product list feature
│   │   ├── feature-product-detail/
│   │   ├── data/                 # Data hooks & API calls
│   │   └── shared-ui/            # Shared components
│   │
│   ├── api/
│   │   └── products/             # API product service
│   │
│   └── shared/
│       ├── models/               # TypeScript interfaces
│       └── test-utils/           # Testing utilities
│
├── tsconfig.base.json            # Base TypeScript config with paths
├── tsconfig.json                 # Root TypeScript config
├── nx.json                       # Nx workspace configuration
├── pnpm-workspace.yaml           # pnpm workspace config
└── package.json                  # Root package.json
```

---

## Module Federation Setup

### How It Works

1. **Shell (Host)** - The main application that loads remote modules at runtime
2. **Remotes** - Independent applications that expose components via Module Federation
3. **Shared Dependencies** - React, React DOM, and React Router are shared to avoid duplication

### Shell Configuration

```typescript
// apps/shell/module-federation.config.ts
import { ModuleFederationConfig } from '@nx/module-federation';

const config: ModuleFederationConfig = {
  name: 'shell',
  remotes: [
    ['products', 'http://localhost:4201/'],
    ['product-detail', 'http://localhost:4202/'],
  ],
};

export default config;
```

### Remote Configuration (Products)

```typescript
// apps/products/module-federation.config.ts
import { ModuleFederationConfig } from '@nx/module-federation';

const config: ModuleFederationConfig = {
  name: 'products',
  exposes: {
    './Module': './src/remote-entry.ts',
  },
};

export default config;
```

### Loading Remotes in Shell

```tsx
// apps/shell/src/app/app.tsx
import { lazy, Suspense } from 'react';
import { Route, Routes } from 'react-router-dom';

// Federated remotes - loaded at runtime
const ProductList = lazy(() => import('products/Module'));
const ProductDetail = lazy(() => import('product-detail/Module'));

export function App() {
  return (
    <Suspense fallback={<LoadingSpinner />}>
      <Routes>
        <Route path="/products" element={<ProductList />} />
        <Route path="/products/:id" element={<ProductDetail />} />
      </Routes>
    </Suspense>
  );
}
```

### Remote Type Declarations

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

## TypeScript Configuration

### Path Mappings

The workspace uses TypeScript path mappings to import libraries:

```json
// tsconfig.base.json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@org/api-products": ["libs/api/products/src/index.ts"],
      "@org/models": ["libs/shared/models/src/index.ts"],
      "@org/shop-data": ["libs/shop/data/src/index.ts"],
      "@org/shop-feature-product-detail": ["libs/shop/feature-product-detail/src/index.ts"],
      "@org/shop-feature-products": ["libs/shop/feature-products/src/index.ts"],
      "@org/shop-shared-ui": ["libs/shop/shared-ui/src/index.ts"],
      "@org/test-utils": ["libs/shared/test-utils/src/index.ts"]
    }
  }
}
```

### Key Configuration Details

| Setting | Value | Purpose |
|---------|-------|---------|
| `composite: false` | Apps & React libs | Allows consuming libraries from source without pre-building |
| `lib: ["es2022", "dom"]` | React apps | DOM types for browser APIs |
| `jsx: "react-jsx"` | React projects | Modern JSX transform |
| `moduleResolution: "bundler"` | Frontend | Webpack/Vite module resolution |
| `moduleResolution: "node"` | Backend | Node.js module resolution |

---

## Development Workflow

### Starting Development

```bash
# Start everything (recommended)
npx nx serve shell

# This starts:
# - API server on port 3333
# - Products remote on port 4201
# - Product-detail remote on port 4202
# - Shell host on port 4200
```

### Running Individual Services

```bash
# Shell only (remotes must be running)
npx nx serve shell --devRemotes=

# Individual remotes
npx nx serve products
npx nx serve product-detail

# API only
npx nx serve api

# Standalone shop app (Vite)
npx nx serve shop
```

### Building for Production

```bash
# Build all projects
npx nx run-many -t build

# Build specific project
npx nx build shell

# Build with production config
npx nx build shell --configuration=production
```

### Testing

```bash
# Unit tests
npx nx test shop-data
npx nx run-many -t test

# E2E tests
npx nx e2e shop-e2e

# Test with coverage
npx nx test shop-data --coverage
```

### Linting

```bash
# Lint specific project
npx nx lint shell

# Lint all projects
npx nx run-many -t lint

# Fix lint issues
npx nx lint shell --fix
```

---

## Available Commands

| Command | Description |
|---------|-------------|
| `npx nx serve shell` | Start full application |
| `npx nx serve shop` | Start standalone Vite app |
| `npx nx serve api` | Start API server only |
| `npx nx build <project>` | Build a project |
| `npx nx test <project>` | Run unit tests |
| `npx nx lint <project>` | Run linting |
| `npx nx e2e shop-e2e` | Run E2E tests |
| `npx nx graph` | Visualize dependency graph |
| `npx nx affected -t <target>` | Run target on affected projects |
| `npx nx run-many -t <target>` | Run target on all projects |
| `npx nx reset` | Clear Nx cache |

---

## Troubleshooting

### Common Issues

#### Port Already in Use

```bash
# Kill processes on specific ports
lsof -ti:4200,4201,4202,3333 | xargs kill -9

# Then restart
npx nx serve shell
```

#### Module Federation Load Errors

If you see `Failed to load script resources` errors:

1. Ensure all remotes are running on their designated ports
2. Check that `module-federation.config.ts` has correct remote URLs
3. Clear cache and rebuild: `npx nx reset && npx nx serve shell`

#### TypeScript Errors

If you see `TS6305: Output file has not been built`:

1. Ensure `composite: false` is set in the app's tsconfig
2. Remove project references from `tsconfig.app.json`
3. Verify the library's tsconfig also has `composite: false`

#### Babel Errors

If you see `Cannot find module .babelrc`:

Ensure each webpack-based app has a `.babelrc` file:

```json
{
  "presets": [
    [
      "@nx/react/babel",
      {
        "runtime": "automatic",
        "useBuiltIns": "usage"
      }
    ]
  ],
  "plugins": []
}
```

#### Nx Sync Issues

If Nx keeps re-adding project references:

The workspace has `typescript-sync` disabled in `nx.json`:

```json
{
  "sync": {
    "disabledTaskSyncGenerators": ["@nx/js:typescript-sync"]
  }
}
```

---

## Module Boundaries

This repository enforces architectural constraints using Nx tags:

| Tag | Description | Can Import |
|-----|-------------|------------|
| `scope:shop` | Shop application code | `scope:shop`, `scope:shared` |
| `scope:api` | API backend code | `scope:api`, `scope:shared` |
| `scope:shared` | Shared utilities | Nothing external |
| `type:feature` | Feature modules | All types |
| `type:data` | Data access layer | `type:data`, `scope:shared` |
| `type:ui` | UI components | `type:ui`, `scope:shared` |

Violations are caught by ESLint during linting.

---

## Learn More

- [Nx Documentation](https://nx.dev)
- [Module Federation Guide](https://nx.dev/concepts/module-federation/module-federation-and-nx)
- [React Monorepo Tutorial](https://nx.dev/getting-started/tutorials/react-monorepo-tutorial)
- [Enforce Module Boundaries](https://nx.dev/features/enforce-module-boundaries)

---

## License

MIT
