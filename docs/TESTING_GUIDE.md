# Testing Guide

This document covers testing practices, tools, and patterns used in this project.

## Table of Contents

- [Overview](#overview)
- [Testing Stack](#testing-stack)
- [Running Tests](#running-tests)
- [Unit Testing Components](#unit-testing-components)
- [Testing Hooks](#testing-hooks)
- [Testing Services](#testing-services)
- [Mocking](#mocking)
- [Test Organization](#test-organization)
- [Best Practices](#best-practices)
- [Coverage](#coverage)

---

## Overview

This project uses a comprehensive testing strategy:

| Test Type | Tool | Location | Purpose |
|-----------|------|----------|---------|
| **Unit** | Vitest | `*.spec.tsx` | Components, hooks, utilities |
| **Integration** | Vitest | `*.spec.ts` | Services, API handlers |
| **E2E** | Playwright | `apps/shop-e2e` | Full user flows |

---

## Testing Stack

| Tool | Purpose |
|------|---------|
| **Vitest** | Test runner (Jest-compatible, Vite-native) |
| **@testing-library/react** | Component testing utilities |
| **@testing-library/jest-dom** | Custom DOM matchers |
| **jsdom** | DOM environment for Node |
| **Supertest** | HTTP assertions for API |

---

## Running Tests

### Basic Commands

```bash
# Run all tests
npx nx run-many -t test

# Test specific project
npx nx test shop-data
npx nx test shop-shared-ui

# Watch mode
npx nx test shop-data --watch

# With coverage
npx nx test shop-data --coverage

# Run single file
npx nx test shop-data --testFile=use-products.spec.ts
```

### Nx Affected

```bash
# Only test affected projects
npx nx affected -t test

# Against specific base
npx nx affected -t test --base=main
```

---

## Unit Testing Components

### Basic Component Test

```tsx
// product-card.spec.tsx
import { render, screen } from '@testing-library/react';
import { ProductCard } from './product-card';

const mockProduct = {
  id: '1',
  name: 'Test Product',
  price: 99.99,
  imageUrl: 'https://example.com/image.jpg',
  category: 'Electronics',
  rating: 4.5,
  reviewCount: 100,
  inStock: true,
};

describe('ProductCard', () => {
  it('should render product name', () => {
    render(<ProductCard {...mockProduct} />);
    
    expect(screen.getByText('Test Product')).toBeInTheDocument();
  });

  it('should render formatted price', () => {
    render(<ProductCard {...mockProduct} />);
    
    expect(screen.getByText('$99.99')).toBeInTheDocument();
  });

  it('should render product image with alt text', () => {
    render(<ProductCard {...mockProduct} />);
    
    const image = screen.getByRole('img');
    expect(image).toHaveAttribute('src', mockProduct.imageUrl);
    expect(image).toHaveAttribute('alt', mockProduct.name);
  });
});
```

### Testing User Interactions

```tsx
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

describe('ProductCard interactions', () => {
  it('should call onSelect when clicked', async () => {
    const onSelect = vi.fn();
    const user = userEvent.setup();
    
    render(<ProductCard {...mockProduct} onSelect={onSelect} />);
    
    await user.click(screen.getByRole('button'));
    
    expect(onSelect).toHaveBeenCalledWith(mockProduct.id);
  });

  it('should call onSelect when Enter key pressed', async () => {
    const onSelect = vi.fn();
    const user = userEvent.setup();
    
    render(<ProductCard {...mockProduct} onSelect={onSelect} />);
    
    const card = screen.getByRole('button');
    card.focus();
    await user.keyboard('{Enter}');
    
    expect(onSelect).toHaveBeenCalledWith(mockProduct.id);
  });
});
```

### Testing with Router

```tsx
import { render, screen } from '@testing-library/react';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { ProductDetail } from './product-detail';

const renderWithRouter = (initialRoute = '/products/1') => {
  return render(
    <MemoryRouter initialEntries={[initialRoute]}>
      <Routes>
        <Route path="/products/:id" element={<ProductDetail />} />
      </Routes>
    </MemoryRouter>
  );
};

describe('ProductDetail', () => {
  it('should render product from route param', async () => {
    renderWithRouter('/products/1');
    
    // Wait for async loading
    expect(await screen.findByText('Product Name')).toBeInTheDocument();
  });
});
```

### Testing Async Components

```tsx
import { render, screen, waitFor } from '@testing-library/react';

describe('ProductList', () => {
  it('should show loading state initially', () => {
    render(<ProductList />);
    
    expect(screen.getByRole('status')).toBeInTheDocument(); // LoadingSpinner
  });

  it('should render products after loading', async () => {
    render(<ProductList />);
    
    // Wait for products to load
    expect(await screen.findByText('Product 1')).toBeInTheDocument();
    expect(screen.getByText('Product 2')).toBeInTheDocument();
  });

  it('should show error message on failure', async () => {
    // Mock API to fail
    vi.mocked(fetchProducts).mockRejectedValueOnce(new Error('Network error'));
    
    render(<ProductList />);
    
    expect(await screen.findByText(/error/i)).toBeInTheDocument();
  });
});
```

---

## Testing Hooks

### Basic Hook Test

```tsx
// use-products.spec.ts
import { renderHook, waitFor } from '@testing-library/react';
import { useProducts } from './use-products';
import { fetchProducts } from './api';

// Mock the API
vi.mock('./api');

const mockProducts = [
  { id: '1', name: 'Product 1', price: 10 },
  { id: '2', name: 'Product 2', price: 20 },
];

describe('useProducts', () => {
  beforeEach(() => {
    vi.mocked(fetchProducts).mockResolvedValue({
      items: mockProducts,
      totalCount: 2,
      page: 1,
      pageSize: 12,
    });
  });

  it('should fetch products on mount', async () => {
    const { result } = renderHook(() => useProducts());

    // Initially loading
    expect(result.current.isLoading).toBe(true);

    // Wait for fetch to complete
    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.products).toEqual(mockProducts);
    expect(result.current.totalCount).toBe(2);
  });

  it('should refetch when filter changes', async () => {
    const { result, rerender } = renderHook(
      ({ filter }) => useProducts({ filter }),
      { initialProps: { filter: {} } }
    );

    await waitFor(() => expect(result.current.isLoading).toBe(false));

    // Change filter
    rerender({ filter: { category: 'Electronics' } });

    // Should be loading again
    expect(result.current.isLoading).toBe(true);

    await waitFor(() => expect(result.current.isLoading).toBe(false));

    expect(fetchProducts).toHaveBeenCalledWith(
      expect.objectContaining({ category: 'Electronics' })
    );
  });

  it('should handle errors', async () => {
    vi.mocked(fetchProducts).mockRejectedValueOnce(new Error('Network error'));

    const { result } = renderHook(() => useProducts());

    await waitFor(() => {
      expect(result.current.error).not.toBeNull();
    });

    expect(result.current.error?.message).toBe('Network error');
    expect(result.current.products).toEqual([]);
  });
});
```

### Hook with Context

```tsx
import { renderHook } from '@testing-library/react';
import { CartProvider, useCart } from './cart-context';

const wrapper = ({ children }: { children: React.ReactNode }) => (
  <CartProvider>{children}</CartProvider>
);

describe('useCart', () => {
  it('should add item to cart', () => {
    const { result } = renderHook(() => useCart(), { wrapper });

    act(() => {
      result.current.addItem({ id: '1', name: 'Product', price: 10 });
    });

    expect(result.current.items).toHaveLength(1);
    expect(result.current.total).toBe(10);
  });
});
```

---

## Testing Services

### API Service Test

```typescript
// products.service.spec.ts
import { ProductsService } from './products.service';
import { Product } from '@org/models';

describe('ProductsService', () => {
  let service: ProductsService;

  beforeEach(() => {
    service = new ProductsService();
  });

  describe('getAll', () => {
    it('should return paginated products', () => {
      const result = service.getAll({ page: 1, pageSize: 10 });

      expect(result.items).toHaveLength(10);
      expect(result.page).toBe(1);
      expect(result.pageSize).toBe(10);
    });

    it('should filter by category', () => {
      const result = service.getAll({ category: 'Electronics' });

      result.items.forEach((product: Product) => {
        expect(product.category).toBe('Electronics');
      });
    });

    it('should filter by search term', () => {
      const result = service.getAll({ search: 'laptop' });

      result.items.forEach((product: Product) => {
        expect(
          product.name.toLowerCase().includes('laptop') ||
          product.description.toLowerCase().includes('laptop')
        ).toBe(true);
      });
    });

    it('should filter by stock status', () => {
      const result = service.getAll({ inStock: true });

      result.items.forEach((product: Product) => {
        expect(product.inStock).toBe(true);
      });
    });
  });

  describe('getById', () => {
    it('should return product by id', () => {
      const product = service.getById('1');

      expect(product).toBeDefined();
      expect(product?.id).toBe('1');
    });

    it('should return undefined for non-existent id', () => {
      const product = service.getById('non-existent');

      expect(product).toBeUndefined();
    });
  });
});
```

### Express API Test

```typescript
// main.spec.ts
import request from 'supertest';
import express from 'express';
import { setupRoutes } from './routes';

describe('API Endpoints', () => {
  const app = express();
  setupRoutes(app);

  describe('GET /api/products', () => {
    it('should return 200 and products array', async () => {
      const response = await request(app).get('/api/products');

      expect(response.status).toBe(200);
      expect(response.body.items).toBeInstanceOf(Array);
      expect(response.body.totalCount).toBeGreaterThan(0);
    });

    it('should support pagination', async () => {
      const response = await request(app)
        .get('/api/products')
        .query({ page: 2, pageSize: 5 });

      expect(response.body.page).toBe(2);
      expect(response.body.pageSize).toBe(5);
    });
  });

  describe('GET /api/products/:id', () => {
    it('should return product by id', async () => {
      const response = await request(app).get('/api/products/1');

      expect(response.status).toBe(200);
      expect(response.body.id).toBe('1');
    });

    it('should return 404 for non-existent product', async () => {
      const response = await request(app).get('/api/products/non-existent');

      expect(response.status).toBe(404);
    });
  });

  describe('GET /health', () => {
    it('should return healthy status', async () => {
      const response = await request(app).get('/health');

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('healthy');
    });
  });
});
```

---

## Mocking

### Mocking Modules

```typescript
// Mock entire module
vi.mock('./api', () => ({
  fetchProducts: vi.fn(),
  fetchProduct: vi.fn(),
}));

// Mock with implementation
vi.mock('./api', () => ({
  fetchProducts: vi.fn().mockResolvedValue({ items: [], totalCount: 0 }),
}));

// Access mocked function
import { fetchProducts } from './api';
vi.mocked(fetchProducts).mockResolvedValueOnce({ items: mockProducts });
```

### Mocking Fetch

```typescript
// Global fetch mock
const mockFetch = vi.fn();
global.fetch = mockFetch;

beforeEach(() => {
  mockFetch.mockResolvedValue({
    ok: true,
    json: () => Promise.resolve({ data: 'test' }),
  });
});

afterEach(() => {
  mockFetch.mockClear();
});
```

### Mocking Timers

```typescript
describe('debounced search', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('should debounce search input', async () => {
    const onSearch = vi.fn();
    render(<SearchInput onSearch={onSearch} debounceMs={300} />);

    await userEvent.type(screen.getByRole('textbox'), 'test');

    // Not called yet
    expect(onSearch).not.toHaveBeenCalled();

    // Fast-forward time
    vi.advanceTimersByTime(300);

    expect(onSearch).toHaveBeenCalledWith('test');
  });
});
```

### Mocking Intersection Observer

```typescript
// test-setup.ts
const mockIntersectionObserver = vi.fn();
mockIntersectionObserver.mockReturnValue({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn(),
});
window.IntersectionObserver = mockIntersectionObserver;
```

---

## Test Organization

### Test File Structure

```typescript
// product-card.spec.tsx
import { render, screen } from '@testing-library/react';
import { ProductCard } from './product-card';

// 1. Mock data at the top
const mockProduct = { /* ... */ };

// 2. Helper functions
const renderComponent = (props = {}) => {
  return render(<ProductCard {...mockProduct} {...props} />);
};

// 3. Describe blocks organized by feature
describe('ProductCard', () => {
  // Rendering tests
  describe('rendering', () => {
    it('should render product name', () => { /* ... */ });
    it('should render product price', () => { /* ... */ });
  });

  // Interaction tests
  describe('interactions', () => {
    it('should call onSelect when clicked', () => { /* ... */ });
  });

  // Edge cases
  describe('edge cases', () => {
    it('should handle missing image', () => { /* ... */ });
    it('should show out of stock badge', () => { /* ... */ });
  });

  // Accessibility
  describe('accessibility', () => {
    it('should have correct aria labels', () => { /* ... */ });
    it('should be keyboard navigable', () => { /* ... */ });
  });
});
```

### Test Setup Files

```typescript
// libs/shop/shared-ui/src/test-setup.ts
import '@testing-library/jest-dom/vitest';
import { cleanup } from '@testing-library/react';
import { afterEach } from 'vitest';

// Cleanup after each test
afterEach(() => {
  cleanup();
});

// Mock window.matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
});
```

---

## Best Practices

### Do's

| Practice | Reason |
|----------|--------|
| Test behavior, not implementation | Tests survive refactors |
| Use semantic queries | `getByRole`, `getByLabelText` |
| One assertion focus per test | Clear failure messages |
| Test edge cases | Empty states, errors, loading |
| Use test IDs sparingly | Only when no semantic option |

### Don'ts

| Anti-Pattern | Problem |
|--------------|---------|
| Testing internal state | Brittle tests |
| Snapshot everything | Hard to review changes |
| Testing library code | Trust your dependencies |
| Coupling to CSS classes | Breaks on style changes |
| Ignoring async behavior | Race conditions |

### Query Priority

```tsx
// Best (accessible)
screen.getByRole('button', { name: /submit/i })
screen.getByLabelText(/email/i)
screen.getByText(/welcome/i)

// Good (semantic)
screen.getByAltText(/profile/i)
screen.getByTitle(/close/i)

// Acceptable (last resort)
screen.getByTestId('custom-element')
```

### Async Best Practices

```tsx
// ✅ Good - use findBy for async
expect(await screen.findByText('Loaded')).toBeInTheDocument();

// ✅ Good - waitFor for assertions
await waitFor(() => {
  expect(screen.getByText('Loaded')).toBeInTheDocument();
});

// ❌ Bad - arbitrary delays
await new Promise(r => setTimeout(r, 1000));
expect(screen.getByText('Loaded')).toBeInTheDocument();
```

---

## Coverage

### Running Coverage

```bash
# Single project
npx nx test shop-data --coverage

# All projects
npx nx run-many -t test --coverage
```

### Coverage Thresholds

```typescript
// vite.config.ts
test: {
  coverage: {
    provider: 'v8',
    reportsDirectory: './test-output/vitest/coverage',
    include: ['src/**/*.{ts,tsx}'],
    exclude: ['src/**/*.spec.{ts,tsx}', 'src/test-setup.ts'],
    thresholds: {
      statements: 80,
      branches: 80,
      functions: 80,
      lines: 80,
    },
  },
}
```

### What to Cover

| Priority | What to Test |
|----------|--------------|
| **High** | Business logic, hooks, utilities |
| **Medium** | Component behavior, user interactions |
| **Low** | Simple presentational components |
| **Skip** | Third-party libraries, generated code |

---

## Related Documentation

- [REACT_PATTERNS.md](./REACT_PATTERNS.md) - Component patterns
- [NX_STRUCTURE.md](./NX_STRUCTURE.md) - Project organization
- [Vitest Documentation](https://vitest.dev/)
- [Testing Library Docs](https://testing-library.com/docs/react-testing-library/intro/)
