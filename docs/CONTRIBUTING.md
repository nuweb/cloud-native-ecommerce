# Contributing Guide

This document provides guidelines for contributing to the Cloud-Native E-Commerce project.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Standards](#code-standards)
- [Commit Conventions](#commit-conventions)
- [Pull Request Process](#pull-request-process)
- [Code Review](#code-review)
- [Testing Requirements](#testing-requirements)

---

## Getting Started

### Prerequisites

- **Node.js** >= 20.x
- **pnpm** >= 8.x
- **Git**

### Setup

```bash
# Clone the repository
git clone https://github.com/nuweb/cloud-native-ecommerce.git
cd cloud-native-ecommerce

# Install dependencies
pnpm install

# Start development server
npx nx serve shell
```

### Verify Setup

```bash
# Run tests
npx nx run-many -t test

# Run linting
npx nx run-many -t lint

# Build all projects
npx nx run-many -t build
```

---

## Development Workflow

### 1. Create a Branch

```bash
# Update main
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/add-cart-functionality

# Or bugfix branch
git checkout -b fix/product-card-overflow
```

### Branch Naming

| Type     | Pattern                  | Example                  |
| -------- | ------------------------ | ------------------------ |
| Feature  | `feature/<description>`  | `feature/add-wishlist`   |
| Bug fix  | `fix/<description>`      | `fix/price-rounding`     |
| Refactor | `refactor/<description>` | `refactor/product-hooks` |
| Docs     | `docs/<description>`     | `docs/api-reference`     |
| Chore    | `chore/<description>`    | `chore/update-deps`      |

### 2. Make Changes

```bash
# Check affected projects
npx nx affected:graph

# Run tests for affected
npx nx affected -t test

# Run linting for affected
npx nx affected -t lint
```

### 3. Commit Changes

Follow [Commit Conventions](#commit-conventions) below.

### 4. Push and Create PR

```bash
git push -u origin feature/add-cart-functionality
```

Then create a Pull Request on GitHub.

---

## Code Standards

### TypeScript

```typescript
// ✅ Use explicit types for function parameters and returns
function calculateTotal(items: CartItem[]): number {
  return items.reduce((sum, item) => sum + item.price, 0);
}

// ✅ Use interfaces for object shapes
interface CartItem {
  id: string;
  name: string;
  price: number;
  quantity: number;
}

// ✅ Use type for unions and intersections
type Status = 'loading' | 'success' | 'error';

// ❌ Avoid `any`
function process(data: any) {} // Bad

// ✅ Use `unknown` and narrow
function process(data: unknown) {
  if (typeof data === 'string') {
    // Now TypeScript knows it's a string
  }
}
```

### React Components

```tsx
// ✅ Use function components
export function ProductCard({ name, price }: ProductCardProps) {
  return (
    <article>
      <h3>{name}</h3>
      <p>${price}</p>
    </article>
  );
}

// ✅ Export types with components
export interface ProductCardProps {
  name: string;
  price: number;
}

// ✅ Use named exports (easier to refactor)
export { ProductCard };

// ✅ Default export for lazy loading
export default ProductCard;
```

### File Organization

```
component/
├── component.tsx          # Component implementation
├── component.spec.tsx     # Tests
├── component.module.css   # Styles
└── index.ts               # Re-exports (optional)
```

### Imports Order

```typescript
// 1. React
import { useState, useEffect } from 'react';

// 2. Third-party libraries
import { useNavigate } from 'react-router-dom';

// 3. Workspace libraries (@org/*)
import { Product } from '@org/models';
import { useProducts } from '@org/shop-data';

// 4. Relative imports
import { ProductCard } from '../product-card/product-card';
import styles from './product-list.module.css';
```

---

## Commit Conventions

We follow [Conventional Commits](https://www.conventionalcommits.org/).

### Format

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

| Type       | Description                                             |
| ---------- | ------------------------------------------------------- |
| `feat`     | New feature                                             |
| `fix`      | Bug fix                                                 |
| `docs`     | Documentation changes                                   |
| `style`    | Formatting, missing semicolons, etc.                    |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf`     | Performance improvement                                 |
| `test`     | Adding or updating tests                                |
| `chore`    | Maintenance tasks, dependencies                         |
| `ci`       | CI/CD changes                                           |

### Scopes

| Scope            | Description           |
| ---------------- | --------------------- |
| `shell`          | Shell application     |
| `products`       | Products remote       |
| `product-detail` | Product detail remote |
| `api`            | Backend API           |
| `shop-data`      | Data library          |
| `shop-ui`        | Shared UI library     |
| `models`         | Models library        |
| `infra`          | Infrastructure        |
| `deps`           | Dependencies          |

### Examples

```bash
# Feature
git commit -m "feat(shop-ui): add ProductCard component"

# Bug fix
git commit -m "fix(api): handle null product category"

# Docs
git commit -m "docs: update API reference"

# With body
git commit -m "feat(products): add category filter

- Add CategoryFilter component
- Update useProducts hook to accept filter
- Add filter state to ProductList"

# Breaking change
git commit -m "feat(api)!: change product response format

BREAKING CHANGE: Product response now includes nested 'data' property"
```

---

## Pull Request Process

### Before Creating PR

- [ ] Tests pass locally (`npx nx affected -t test`)
- [ ] Lint passes (`npx nx affected -t lint`)
- [ ] Build succeeds (`npx nx affected -t build`)
- [ ] Commits follow conventions
- [ ] Branch is up to date with main

### PR Template

```markdown
## Description

Brief description of changes.

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## How to Test

1. Step one
2. Step two
3. Expected result

## Checklist

- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No console.log statements
- [ ] No commented-out code

## Screenshots (if applicable)
```

### PR Title

Follow commit convention for PR title:

```
feat(shop-ui): add ProductCard component
fix(api): handle null product category
```

---

## Code Review

### For Authors

1. **Keep PRs small** - Easier to review, faster to merge
2. **Self-review first** - Check your own diff before requesting review
3. **Respond promptly** - Address feedback within 24 hours
4. **Be open to feedback** - Different perspectives improve code

### For Reviewers

1. **Be constructive** - Suggest improvements, don't just criticize
2. **Ask questions** - "Why did you choose this approach?"
3. **Approve when satisfied** - Don't block on nitpicks
4. **Use suggestions** - GitHub's suggestion feature for small changes

### Review Checklist

- [ ] Code follows project standards
- [ ] Tests cover new functionality
- [ ] No security vulnerabilities
- [ ] No performance issues
- [ ] Documentation updated if needed
- [ ] Commits are well-organized

### Feedback Labels

| Label         | Meaning                        |
| ------------- | ------------------------------ |
| `nit:`        | Minor suggestion, not blocking |
| `question:`   | Seeking clarification          |
| `suggestion:` | Recommended improvement        |
| `issue:`      | Must be addressed before merge |

---

## Testing Requirements

### Coverage Requirements

| Metric     | Minimum |
| ---------- | ------- |
| Statements | 80%     |
| Branches   | 80%     |
| Functions  | 80%     |
| Lines      | 80%     |

### What Must Be Tested

| Type       | Requirement                            |
| ---------- | -------------------------------------- |
| Components | Render, interactions, edge cases       |
| Hooks      | State changes, effects, error handling |
| Services   | All public methods                     |
| Utilities  | All exported functions                 |

### Test Commands

```bash
# Run all tests
npx nx run-many -t test

# Run with coverage
npx nx test shop-data --coverage

# Run specific test file
npx nx test shop-data --testFile=use-products.spec.ts

# Watch mode
npx nx test shop-data --watch
```

---

## Quick Reference

### Common Commands

```bash
# Start development
npx nx serve shell

# Run tests
npx nx run-many -t test

# Run linting
npx nx run-many -t lint

# Build all
npx nx run-many -t build

# View dependency graph
npx nx graph

# Generate component
npx nx g @nx/react:component my-component --project=shop-shared-ui

# Generate library
npx nx g @nx/react:library my-lib --directory=libs/shop
```

### Useful Links

- [Nx Documentation](https://nx.dev)
- [React Documentation](https://react.dev)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/)
- [Testing Library](https://testing-library.com/docs/react-testing-library/intro/)

---

## Getting Help

- **Questions?** Open a GitHub Discussion
- **Bug found?** Create an Issue
- **Feature idea?** Create an Issue with `enhancement` label

---

## Related Documentation

- [REACT_PATTERNS.md](./REACT_PATTERNS.md) - Component patterns
- [TESTING_GUIDE.md](./TESTING_GUIDE.md) - Testing guide
- [NX_STRUCTURE.md](./NX_STRUCTURE.md) - Project structure
- [TECH_STACK.md](./TECH_STACK.md) - Technology overview
