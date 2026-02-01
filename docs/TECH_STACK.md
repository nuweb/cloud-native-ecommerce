# Technology Stack

This document provides a comprehensive overview of all tools, libraries, and frameworks used in the Cloud-Native E-Commerce platform.

## Frontend

| Category              | Technology            | Version | Purpose                                |
| --------------------- | --------------------- | ------- | -------------------------------------- |
| **UI Framework**      | React                 | 19.0.0  | Component-based UI development         |
| **Routing**           | React Router DOM      | 6.30.3  | Client-side routing                    |
| **Build Tool**        | Webpack               | 5.x     | Module bundling for MFE apps           |
| **Build Tool**        | Vite                  | 7.0.0   | Fast dev server & build (shop app)     |
| **Module Federation** | @nx/module-federation | 22.4.1  | Microfrontend architecture             |
| **Transpiler**        | SWC                   | 1.15.10 | Fast TypeScript/JavaScript compilation |
| **Transpiler**        | Babel                 | 7.14.5  | JSX transformation                     |

## Backend

| Category          | Technology | Version | Purpose               |
| ----------------- | ---------- | ------- | --------------------- |
| **Runtime**       | Node.js    | 20.x    | JavaScript runtime    |
| **Web Framework** | Express.js | 4.21.2  | REST API server       |
| **Bundler**       | esbuild    | 0.19.2  | Fast backend bundling |

## Monorepo & Build System

| Category            | Technology      | Version | Purpose                                       |
| ------------------- | --------------- | ------- | --------------------------------------------- |
| **Monorepo Tool**   | Nx              | 22.4.0  | Task orchestration, caching, dependency graph |
| **Package Manager** | pnpm            | 8.x     | Fast, disk-efficient package management       |
| **Language**        | TypeScript      | 5.9.2   | Type-safe JavaScript                          |
| **Workspace**       | pnpm workspaces | -       | Multi-package repository                      |

## Testing

| Category              | Technology                | Version | Purpose                  |
| --------------------- | ------------------------- | ------- | ------------------------ |
| **Unit Test Runner**  | Vitest                    | 4.0.9   | Fast unit testing        |
| **E2E Testing**       | Playwright                | 1.36.0  | Cross-browser E2E tests  |
| **Component Testing** | @testing-library/react    | 16.1.0  | React component testing  |
| **DOM Testing**       | jsdom                     | 22.1.0  | DOM simulation for tests |
| **API Testing**       | Supertest                 | 7.1.4   | HTTP assertions          |
| **Coverage**          | @vitest/coverage-v8       | 4.0.9   | Code coverage reports    |
| **DOM Matchers**      | @testing-library/jest-dom | 6.8.0   | Custom DOM matchers      |

## Code Quality

| Category           | Technology                | Version | Purpose                          |
| ------------------ | ------------------------- | ------- | -------------------------------- |
| **Linting**        | ESLint                    | 9.8.0   | Code quality & style enforcement |
| **Formatting**     | Prettier                  | 2.6.2   | Code formatting                  |
| **Type Checking**  | TypeScript                | 5.9.2   | Static type analysis             |
| **Import Linting** | eslint-plugin-import      | 2.31.0  | Import/export validation         |
| **Accessibility**  | eslint-plugin-jsx-a11y    | 6.10.1  | Accessibility checks             |
| **React Rules**    | eslint-plugin-react       | 7.35.0  | React-specific linting           |
| **Hooks Rules**    | eslint-plugin-react-hooks | 5.0.0   | React Hooks linting              |

## AWS Infrastructure

| Service        | Purpose                                                           |
| -------------- | ----------------------------------------------------------------- |
| **S3**         | Static frontend hosting (shell, products, product-detail buckets) |
| **CloudFront** | CDN with SSL termination, caching, and custom routing             |
| **App Runner** | Managed container hosting for API                                 |
| **ECR**        | Docker image registry                                             |
| **Route 53**   | DNS management and domain routing                                 |
| **ACM**        | SSL/TLS certificate management                                    |
| **IAM**        | Access control and permissions                                    |

## CI/CD & DevOps

| Tool               | Purpose                                   |
| ------------------ | ----------------------------------------- |
| **GitHub Actions** | Automated CI/CD pipelines                 |
| **Terraform**      | Infrastructure as Code (AWS provisioning) |
| **Docker**         | API containerization                      |

## Architecture Patterns

### Microfrontends

- **Webpack Module Federation** enables independent deployment of frontend apps
- **Shell (Host)** loads remote microfrontends at runtime
- **Shared dependencies** (React, React Router) avoid duplication

### Monorepo Structure

```
apps/           # Deployable applications
├── shell/      # MFE host (Webpack)
├── products/   # MFE remote (Webpack)
├── product-detail/  # MFE remote (Webpack)
├── shop/       # Standalone app (Vite)
└── api/        # Backend (Express)

libs/           # Shared libraries
├── shop/       # Frontend libraries
│   ├── feature-products/
│   ├── feature-product-detail/
│   ├── data/
│   └── shared-ui/
├── api/        # Backend libraries
│   └── products/
└── shared/     # Cross-cutting libraries
    ├── models/
    └── test-utils/
```

### Key Design Decisions

| Decision              | Rationale                                                  |
| --------------------- | ---------------------------------------------------------- |
| **Module Federation** | Independent deployments, team autonomy                     |
| **Nx Monorepo**       | Code sharing, consistent tooling, affected commands        |
| **pnpm**              | Faster installs, disk efficiency, strict dependencies      |
| **TypeScript**        | Type safety, better IDE support, refactoring confidence    |
| **Vitest**            | Fast tests, Vite-compatible, modern API                    |
| **App Runner**        | Managed containers, auto-scaling, no Kubernetes complexity |
| **CloudFront + S3**   | Cost-effective, globally distributed static hosting        |

## Version Compatibility

| Requirement | Version |
| ----------- | ------- |
| Node.js     | >= 20.x |
| pnpm        | >= 8.x  |
| TypeScript  | ~5.9.x  |
| React       | 19.x    |

## Related Documentation

- [README.md](../README.md) - Project overview and quick start
- [AWS_DEPLOYMENT.md](./AWS_DEPLOYMENT.md) - AWS infrastructure details
- [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - Step-by-step deployment guide
