# Nx Monorepo Structure

This document explains the directory structure, conventions, and architecture of this Nx monorepo.

## Table of Contents

- [Overview](#overview)
- [Root Directory](#root-directory)
- [Applications (`apps/`)](#applications-apps)
- [Libraries (`libs/`)](#libraries-libs)
- [Infrastructure (`infra/`)](#infrastructure-infra)
- [Configuration Files](#configuration-files)
- [Naming Conventions](#naming-conventions)
- [Project Tags & Boundaries](#project-tags--boundaries)
- [Dependency Graph](#dependency-graph)

---

## Overview

This is an **Nx integrated monorepo** containing multiple applications and shared libraries. Nx provides:

- **Task orchestration** - Run builds, tests, and lints efficiently
- **Caching** - Skip redundant work with local and remote caching
- **Affected commands** - Only run tasks on changed projects
- **Code generators** - Scaffold new apps and libs consistently
- **Dependency graph** - Visualize project relationships

```
cloud-native-ecommerce/
├── apps/                    # Deployable applications
├── libs/                    # Shared libraries
├── infra/                   # Terraform infrastructure
├── docs/                    # Documentation
├── nx.json                  # Nx configuration
├── tsconfig.base.json       # Shared TypeScript config
├── package.json             # Root dependencies
└── pnpm-workspace.yaml      # pnpm workspace config
```

---

## Root Directory

### Key Files

| File                                  | Purpose                                           |
| ------------------------------------- | ------------------------------------------------- |
| `nx.json`                             | Nx workspace configuration, task runners, plugins |
| `tsconfig.base.json`                  | Shared TypeScript settings and path mappings      |
| `package.json`                        | Root dependencies and workspace scripts           |
| `pnpm-workspace.yaml`                 | Defines which folders are workspace packages      |
| `pnpm-lock.yaml`                      | Locked dependency versions                        |
| `.eslintrc.json` / `eslint.config.js` | Root ESLint configuration                         |
| `.prettierrc`                         | Prettier formatting rules                         |

### `tsconfig.base.json` Path Mappings

```json
{
  "compilerOptions": {
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

These mappings allow importing libraries by alias:

```typescript
import { Product } from '@org/models';
import { useProducts } from '@org/shop-data';
```

---

## Applications (`apps/`)

Applications are **deployable units**. Each app has its own build, serve, and test targets.

```
apps/
├── shell/                   # Module Federation Host
├── products/                # Module Federation Remote
├── product-detail/          # Module Federation Remote
├── shop/                    # Standalone Vite App
├── shop-e2e/                # E2E Tests (Playwright)
└── api/                     # Express.js Backend
```

### Application Structure

Each application follows a consistent structure:

```
apps/shell/
├── src/
│   ├── app/
│   │   ├── app.tsx          # Main component
│   │   ├── app.spec.tsx     # Component tests
│   │   └── app.module.css   # Styles
│   ├── assets/              # Static assets
│   ├── bootstrap.tsx        # React bootstrap (for MFE)
│   ├── main.tsx             # Entry point
│   └── remotes.d.ts         # Type declarations for remotes
├── project.json             # Nx project configuration
├── tsconfig.json            # TypeScript config (extends base)
├── tsconfig.app.json        # App-specific TS config
├── tsconfig.spec.json       # Test-specific TS config
├── webpack.config.ts        # Webpack configuration
├── module-federation.config.ts  # MFE configuration
├── .babelrc                 # Babel configuration
└── package.json             # App-specific dependencies
```

### Application Types

| App              | Type       | Build Tool | Port | Description                |
| ---------------- | ---------- | ---------- | ---- | -------------------------- |
| `shell`          | MFE Host   | Webpack    | 4200 | Main entry, loads remotes  |
| `products`       | MFE Remote | Webpack    | 4201 | Product listing            |
| `product-detail` | MFE Remote | Webpack    | 4202 | Product details            |
| `shop`           | Standalone | Vite       | 4200 | Alternative monolithic app |
| `api`            | Backend    | esbuild    | 3333 | REST API server            |

### `project.json` Example

```json
{
  "name": "shell",
  "projectType": "application",
  "sourceRoot": "apps/shell/src",
  "tags": ["scope:shop", "type:app"],
  "targets": {
    "build": {
      "executor": "@nx/webpack:webpack",
      "options": { ... }
    },
    "serve": {
      "executor": "@nx/module-federation:dev-server",
      "options": { ... }
    },
    "test": {
      "executor": "@nx/vite:test",
      "options": { ... }
    }
  }
}
```

---

## Libraries (`libs/`)

Libraries are **shared code** organized by scope and type. They are consumed by applications but not deployed independently.

```
libs/
├── api/                     # Backend libraries
│   └── products/            # Products service
├── shared/                  # Cross-cutting libraries
│   ├── models/              # TypeScript interfaces
│   └── test-utils/          # Testing utilities
└── shop/                    # Frontend libraries
    ├── data/                # Data fetching hooks
    ├── feature-product-detail/  # Product detail feature
    ├── feature-products/    # Product list feature
    └── shared-ui/           # Shared UI components
```

### Library Structure

```
libs/shop/shared-ui/
├── src/
│   ├── index.ts             # Public API (barrel export)
│   ├── lib/
│   │   ├── product-card/
│   │   │   ├── product-card.tsx
│   │   │   ├── product-card.spec.tsx
│   │   │   └── product-card.module.css
│   │   ├── loading-spinner/
│   │   └── error-message/
│   └── test-setup.ts        # Test configuration
├── project.json             # Nx project configuration
├── tsconfig.json            # TypeScript config
├── tsconfig.lib.json        # Library TS config
├── tsconfig.spec.json       # Test TS config
├── vite.config.ts           # Vite/Vitest configuration
├── package.json             # Library dependencies
└── README.md                # Library documentation
```

### Library Types

| Type        | Prefix       | Purpose                          | Example            |
| ----------- | ------------ | -------------------------------- | ------------------ |
| **feature** | `feature-`   | Smart components, business logic | `feature-products` |
| **data**    | `data`       | Data fetching, state management  | `data`             |
| **ui**      | `shared-ui`  | Presentational components        | `shared-ui`        |
| **util**    | `test-utils` | Utility functions                | `test-utils`       |
| **models**  | `models`     | TypeScript interfaces            | `models`           |

### Library Scopes

| Scope    | Location       | Purpose                               |
| -------- | -------------- | ------------------------------------- |
| `shop`   | `libs/shop/`   | Frontend-specific code                |
| `api`    | `libs/api/`    | Backend-specific code                 |
| `shared` | `libs/shared/` | Code shared across frontend & backend |

### Public API (`index.ts`)

Each library exposes a public API via `src/index.ts`:

```typescript
// libs/shop/shared-ui/src/index.ts
export { ProductCard } from './lib/product-card/product-card';
export { LoadingSpinner } from './lib/loading-spinner/loading-spinner';
export { ErrorMessage } from './lib/error-message/error-message';
export { ProductGrid } from './lib/product-grid/product-grid';
```

---

## Infrastructure (`infra/`)

Terraform configuration for AWS deployment.

```
infra/
├── main.tf                  # S3, CloudFront, ACM, Route 53
├── api.tf                   # ECR, App Runner
├── variables.tf             # Input variables
├── outputs.tf               # Output values
├── providers.tf             # AWS provider config
└── terraform.tfstate        # State file (gitignored)
```

---

## Configuration Files

### Nx Configuration (`nx.json`)

```json
{
  "$schema": "./node_modules/nx/schemas/nx-schema.json",
  "defaultBase": "main",
  "namedInputs": {
    "default": ["{projectRoot}/**/*", "sharedGlobals"],
    "production": ["default", "!{projectRoot}/**/*.spec.tsx"]
  },
  "targetDefaults": {
    "build": {
      "dependsOn": ["^build"],
      "cache": true
    },
    "test": {
      "cache": true
    }
  },
  "plugins": ["@nx/webpack/plugin", "@nx/vite/plugin", "@nx/eslint/plugin"]
}
```

### TypeScript Configs

| Config               | Purpose                              |
| -------------------- | ------------------------------------ |
| `tsconfig.base.json` | Shared settings, path mappings       |
| `tsconfig.json`      | Root config, references all projects |
| `tsconfig.app.json`  | App build configuration              |
| `tsconfig.lib.json`  | Library build configuration          |
| `tsconfig.spec.json` | Test configuration                   |

---

## Naming Conventions

### Projects

| Type        | Pattern                  | Example                 |
| ----------- | ------------------------ | ----------------------- |
| App         | `{name}`                 | `shell`, `api`, `shop`  |
| Feature lib | `{scope}-feature-{name}` | `shop-feature-products` |
| Data lib    | `{scope}-data`           | `shop-data`             |
| UI lib      | `{scope}-shared-ui`      | `shop-shared-ui`        |
| Util lib    | `{scope}-{name}`         | `shared-test-utils`     |

### Import Aliases

| Pattern                      | Example                      |
| ---------------------------- | ---------------------------- |
| `@org/{scope}-{type}-{name}` | `@org/shop-feature-products` |
| `@org/{type}`                | `@org/models`                |

### Files

| Type      | Pattern             | Example                   |
| --------- | ------------------- | ------------------------- |
| Component | `{name}.tsx`        | `product-card.tsx`        |
| Test      | `{name}.spec.tsx`   | `product-card.spec.tsx`   |
| Styles    | `{name}.module.css` | `product-card.module.css` |
| Hook      | `use-{name}.ts`     | `use-products.ts`         |
| Service   | `{name}.service.ts` | `products.service.ts`     |

---

## Project Tags & Boundaries

### Tags

Projects are tagged for dependency enforcement:

```json
// project.json
{
  "tags": ["scope:shop", "type:feature"]
}
```

### Tag Categories

| Category | Values                                 |
| -------- | -------------------------------------- |
| `scope`  | `shop`, `api`, `shared`                |
| `type`   | `app`, `feature`, `data`, `ui`, `util` |

### Dependency Rules

Configured in `.eslintrc.json` or `eslint.config.js`:

| Source         | Can Import                   |
| -------------- | ---------------------------- |
| `scope:shop`   | `scope:shop`, `scope:shared` |
| `scope:api`    | `scope:api`, `scope:shared`  |
| `scope:shared` | `scope:shared` only          |
| `type:feature` | All types                    |
| `type:ui`      | `type:ui`, `scope:shared`    |
| `type:data`    | `type:data`, `scope:shared`  |

---

## Dependency Graph

Visualize the project dependency graph:

```bash
npx nx graph
```

### Current Dependencies

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

   ┌──────────┐
   │   api    │
   └────┬─────┘
        │
        ▼
   ┌──────────────┐
   │ api-products │
   └──────┬───────┘
          │
          ▼
   ┌──────────┐
   │  models  │
   └──────────┘
```

---

## Common Commands

| Command                             | Description            |
| ----------------------------------- | ---------------------- |
| `npx nx graph`                      | Open dependency graph  |
| `npx nx show project shell`         | Show project details   |
| `npx nx list`                       | List installed plugins |
| `npx nx generate @nx/react:library` | Generate new library   |
| `npx nx affected -t test`           | Test affected projects |
| `npx nx run-many -t build`          | Build all projects     |

---

## Related Documentation

- [Nx Documentation](https://nx.dev)
- [TECH_STACK.md](./TECH_STACK.md) - Technology overview
- [README.md](../README.md) - Project overview
