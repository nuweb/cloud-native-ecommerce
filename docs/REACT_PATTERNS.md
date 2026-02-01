# React Patterns & Component Guidelines

This document covers React component structure, patterns, and best practices used in this project.

## Table of Contents

- [Component Structure](#component-structure)
- [File Organization](#file-organization)
- [Component Types](#component-types)
- [Hooks Patterns](#hooks-patterns)
- [State Management](#state-management)
- [Props & TypeScript](#props--typescript)
- [Styling](#styling)
- [Performance](#performance)
- [Accessibility](#accessibility)

---

## Component Structure

### Standard Component Template

```tsx
// product-card.tsx
import { memo } from 'react';
import styles from './product-card.module.css';

// 1. Types/Interfaces at the top
export interface ProductCardProps {
  id: string;
  name: string;
  price: number;
  imageUrl: string;
  onSelect?: (id: string) => void;
}

// 2. Component definition
export function ProductCard({ id, name, price, imageUrl, onSelect }: ProductCardProps) {
  // 3. Hooks first
  const handleClick = () => onSelect?.(id);

  // 4. Early returns for edge cases
  if (!name) return null;

  // 5. Render
  return (
    <article
      className={styles.card}
      onClick={handleClick}
      role="button"
      tabIndex={0}
      aria-label={`View details for ${name}`}
    >
      <img src={imageUrl} alt={name} className={styles.image} />
      <h3 className={styles.name}>{name}</h3>
      <p className={styles.price}>${price.toFixed(2)}</p>
    </article>
  );
}

// 6. Memoize if needed
export default memo(ProductCard);
```

### Component Anatomy

```
┌─────────────────────────────────────┐
│ 1. Imports                          │
│    - React hooks                    │
│    - Components                     │
│    - Styles                         │
│    - Types                          │
├─────────────────────────────────────┤
│ 2. Types/Interfaces                 │
│    - Props interface                │
│    - Local types                    │
├─────────────────────────────────────┤
│ 3. Component Function               │
│    - Destructure props              │
│    - Hooks (useState, useEffect)    │
│    - Event handlers                 │
│    - Early returns                  │
│    - JSX return                     │
├─────────────────────────────────────┤
│ 4. Export                           │
│    - Named export (preferred)       │
│    - Default export (for lazy)      │
└─────────────────────────────────────┘
```

---

## File Organization

### Component Folder Structure

```
libs/shop/shared-ui/src/lib/
├── product-card/
│   ├── product-card.tsx           # Component
│   ├── product-card.spec.tsx      # Tests
│   ├── product-card.module.css    # Styles
│   └── index.ts                   # Re-export (optional)
├── loading-spinner/
│   ├── loading-spinner.tsx
│   ├── loading-spinner.spec.tsx
│   └── loading-spinner.module.css
└── index.ts                       # Barrel export
```

### Barrel Exports

```typescript
// libs/shop/shared-ui/src/index.ts
export { ProductCard } from './lib/product-card/product-card';
export type { ProductCardProps } from './lib/product-card/product-card';
export { LoadingSpinner } from './lib/loading-spinner/loading-spinner';
export { ErrorMessage } from './lib/error-message/error-message';
export { ProductGrid } from './lib/product-grid/product-grid';
```

### Naming Conventions

| Type           | Convention          | Example                   |
| -------------- | ------------------- | ------------------------- |
| Component file | `kebab-case.tsx`    | `product-card.tsx`        |
| Component name | `PascalCase`        | `ProductCard`             |
| Hook file      | `use-kebab-case.ts` | `use-products.ts`         |
| Hook name      | `useCamelCase`      | `useProducts`             |
| Style file     | `*.module.css`      | `product-card.module.css` |
| Test file      | `*.spec.tsx`        | `product-card.spec.tsx`   |
| Type/Interface | `PascalCase`        | `ProductCardProps`        |

---

## Component Types

### 1. Presentational Components (UI)

Pure components that receive data via props and render UI.

```tsx
// libs/shop/shared-ui - Presentational
export function ProductCard({ name, price, imageUrl }: ProductCardProps) {
  return (
    <article className={styles.card}>
      <img src={imageUrl} alt={name} />
      <h3>{name}</h3>
      <p>${price}</p>
    </article>
  );
}
```

**Characteristics:**

- No data fetching
- No side effects
- Easily testable
- Reusable across features

### 2. Container Components (Feature)

Components that manage state and data fetching.

```tsx
// libs/shop/feature-products - Container
export function ProductList() {
  const { products, isLoading, error } = useProducts();

  if (isLoading) return <LoadingSpinner />;
  if (error) return <ErrorMessage message={error.message} />;

  return <ProductGrid products={products} />;
}
```

**Characteristics:**

- Fetches data
- Manages local state
- Composes presentational components
- Feature-specific

### 3. Layout Components

Components that handle page structure.

```tsx
// Layout component
export function PageLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className={styles.layout}>
      <Header />
      <main className={styles.main}>{children}</main>
      <Footer />
    </div>
  );
}
```

### 4. Higher-Order Components (Sparingly)

```tsx
// Use sparingly - prefer hooks or composition
function withAuth<P>(Component: React.ComponentType<P>) {
  return function AuthenticatedComponent(props: P) {
    const { isAuthenticated } = useAuth();
    if (!isAuthenticated) return <Navigate to="/login" />;
    return <Component {...props} />;
  };
}
```

---

## Hooks Patterns

### Custom Data Fetching Hook

```typescript
// libs/shop/data/src/lib/use-products.ts
import { useState, useEffect } from 'react';
import { Product, ProductFilter, PaginatedResponse } from '@org/models';
import { fetchProducts } from './api';

interface UseProductsOptions {
  filter?: ProductFilter;
  page?: number;
  pageSize?: number;
}

interface UseProductsResult {
  products: Product[];
  totalCount: number;
  isLoading: boolean;
  error: Error | null;
  refetch: () => void;
}

export function useProducts(options: UseProductsOptions = {}): UseProductsResult {
  const { filter, page = 1, pageSize = 12 } = options;

  const [products, setProducts] = useState<Product[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchData = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const response = await fetchProducts({ ...filter, page, pageSize });
      setProducts(response.items);
      setTotalCount(response.totalCount);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch'));
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [filter?.category, filter?.search, filter?.inStock, page, pageSize]);

  return { products, totalCount, isLoading, error, refetch: fetchData };
}
```

### Hook Rules

1. **Start with `use`** - `useProducts`, `useAuth`
2. **Call at top level** - Not in conditions or loops
3. **Return consistent shape** - Same properties always
4. **Handle cleanup** - Return cleanup function in useEffect

```typescript
useEffect(() => {
  const controller = new AbortController();

  fetchData(controller.signal);

  return () => controller.abort(); // Cleanup
}, [dependency]);
```

### Common Hook Patterns

```typescript
// Toggle state
function useToggle(initial = false) {
  const [value, setValue] = useState(initial);
  const toggle = useCallback(() => setValue((v) => !v), []);
  return [value, toggle] as const;
}

// Previous value
function usePrevious<T>(value: T): T | undefined {
  const ref = useRef<T>();
  useEffect(() => {
    ref.current = value;
  }, [value]);
  return ref.current;
}

// Debounced value
function useDebounce<T>(value: T, delay: number): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);
  return debounced;
}
```

---

## State Management

### Local State (useState)

```tsx
// Simple local state
const [count, setCount] = useState(0);
const [user, setUser] = useState<User | null>(null);
```

### Derived State

```tsx
// Don't store what you can compute
function ProductList({ products }: { products: Product[] }) {
  // ✅ Derived - computed on render
  const inStockCount = products.filter((p) => p.inStock).length;

  // ❌ Don't duplicate in state
  // const [inStockCount, setInStockCount] = useState(0);
}
```

### Lifting State

```tsx
// Parent owns state, children receive via props
function ProductPage() {
  const [selectedCategory, setSelectedCategory] = useState<string>('');

  return (
    <>
      <CategoryFilter selected={selectedCategory} onSelect={setSelectedCategory} />
      <ProductList category={selectedCategory} />
    </>
  );
}
```

### Context for Global State

```tsx
// contexts/cart-context.tsx
interface CartContextValue {
  items: CartItem[];
  addItem: (product: Product) => void;
  removeItem: (id: string) => void;
  total: number;
}

const CartContext = createContext<CartContextValue | null>(null);

export function CartProvider({ children }: { children: React.ReactNode }) {
  const [items, setItems] = useState<CartItem[]>([]);

  const addItem = useCallback((product: Product) => {
    setItems((prev) => [...prev, { ...product, quantity: 1 }]);
  }, []);

  const removeItem = useCallback((id: string) => {
    setItems((prev) => prev.filter((item) => item.id !== id));
  }, []);

  const total = useMemo(
    () => items.reduce((sum, item) => sum + item.price * item.quantity, 0),
    [items]
  );

  return (
    <CartContext.Provider value={{ items, addItem, removeItem, total }}>
      {children}
    </CartContext.Provider>
  );
}

export function useCart() {
  const context = useContext(CartContext);
  if (!context) throw new Error('useCart must be used within CartProvider');
  return context;
}
```

---

## Props & TypeScript

### Props Interface Patterns

```typescript
// Required vs optional
interface ButtonProps {
  label: string; // Required
  onClick?: () => void; // Optional
  disabled?: boolean; // Optional with default
  variant?: 'primary' | 'secondary'; // Union type
}

// With children
interface CardProps {
  title: string;
  children: React.ReactNode;
}

// Extending HTML elements
interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label: string;
  error?: string;
}

// Generic props
interface ListProps<T> {
  items: T[];
  renderItem: (item: T) => React.ReactNode;
  keyExtractor: (item: T) => string;
}
```

### Default Props

```tsx
// Using default parameters (preferred)
function Button({ variant = 'primary', disabled = false, ...props }: ButtonProps) {
  return <button className={styles[variant]} disabled={disabled} {...props} />;
}
```

### Discriminated Unions

```typescript
// Different props based on variant
type AlertProps =
  | { variant: 'success'; message: string }
  | { variant: 'error'; message: string; onRetry: () => void }
  | { variant: 'loading' };

function Alert(props: AlertProps) {
  switch (props.variant) {
    case 'success':
      return <div className="success">{props.message}</div>;
    case 'error':
      return (
        <div className="error">
          {props.message}
          <button onClick={props.onRetry}>Retry</button>
        </div>
      );
    case 'loading':
      return <LoadingSpinner />;
  }
}
```

---

## Styling

### CSS Modules

```tsx
// Import styles
import styles from './product-card.module.css';

// Use in component
<div className={styles.card}>
  <h3 className={styles.title}>{name}</h3>
</div>;
```

```css
/* product-card.module.css */
.card {
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  padding: 16px;
}

.title {
  font-size: 1.25rem;
  margin: 0;
}

/* Compose styles */
.cardHighlighted {
  composes: card;
  border-color: #007bff;
}
```

### Conditional Classes

```tsx
// Multiple classes
<div className={`${styles.card} ${styles.highlighted}`}>

// Conditional
<div className={`${styles.card} ${isActive ? styles.active : ''}`}>

// With classnames library (if added)
<div className={classNames(styles.card, { [styles.active]: isActive })}>
```

### CSS Variables for Theming

```css
/* styles.css (global) */
:root {
  --color-primary: #007bff;
  --color-text: #333;
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --border-radius: 8px;
}

/* component.module.css */
.button {
  background: var(--color-primary);
  padding: var(--spacing-sm) var(--spacing-md);
  border-radius: var(--border-radius);
}
```

---

## Performance

### Memoization

```tsx
// Memo for expensive renders
const ProductCard = memo(function ProductCard({ product }: Props) {
  return <div>{/* ... */}</div>;
});

// useMemo for expensive computations
const sortedProducts = useMemo(() => products.sort((a, b) => a.price - b.price), [products]);

// useCallback for stable function references
const handleClick = useCallback(
  (id: string) => {
    onSelect(id);
  },
  [onSelect]
);
```

### When to Memoize

| Scenario                             | Solution                      |
| ------------------------------------ | ----------------------------- |
| Component re-renders with same props | `memo()`                      |
| Expensive calculation                | `useMemo()`                   |
| Function passed to memoized child    | `useCallback()`               |
| Large lists                          | Virtualization (react-window) |

### Code Splitting

```tsx
// Lazy load routes
const ProductDetail = lazy(() => import('./ProductDetail'));

// With Suspense
<Suspense fallback={<LoadingSpinner />}>
  <ProductDetail />
</Suspense>;
```

---

## Accessibility

### Semantic HTML

```tsx
// ✅ Good
<article>
  <h2>{product.name}</h2>
  <p>{product.description}</p>
  <button onClick={handleBuy}>Buy Now</button>
</article>

// ❌ Bad
<div>
  <div className="title">{product.name}</div>
  <div>{product.description}</div>
  <div onClick={handleBuy}>Buy Now</div>
</div>
```

### ARIA Attributes

```tsx
// Interactive elements
<button
  aria-label="Close dialog"
  aria-pressed={isPressed}
>
  <CloseIcon />
</button>

// Loading states
<div aria-busy={isLoading} aria-live="polite">
  {isLoading ? <Spinner /> : content}
</div>

// Lists
<ul role="list" aria-label="Product list">
  {products.map(p => (
    <li key={p.id} role="listitem">{p.name}</li>
  ))}
</ul>
```

### Keyboard Navigation

```tsx
function ProductCard({ onSelect }: Props) {
  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      onSelect();
    }
  };

  return (
    <article tabIndex={0} role="button" onClick={onSelect} onKeyDown={handleKeyDown}>
      {/* ... */}
    </article>
  );
}
```

### Focus Management

```tsx
function Dialog({ isOpen, onClose }: Props) {
  const closeButtonRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (isOpen) {
      closeButtonRef.current?.focus();
    }
  }, [isOpen]);

  return isOpen ? (
    <div role="dialog" aria-modal="true">
      <button ref={closeButtonRef} onClick={onClose}>
        Close
      </button>
    </div>
  ) : null;
}
```

---

## Anti-Patterns to Avoid

| Anti-Pattern                | Problem                           | Solution                      |
| --------------------------- | --------------------------------- | ----------------------------- |
| Props drilling              | Passing props through many levels | Context or composition        |
| Giant components            | Hard to test and maintain         | Split into smaller components |
| useEffect for derived state | Unnecessary re-renders            | Compute during render         |
| Index as key                | Causes bugs with reordering       | Use unique IDs                |
| Inline objects/functions    | Creates new reference each render | useMemo/useCallback           |
| Mutating state directly     | React won't detect changes        | Always create new objects     |

---

## Related Documentation

- [TESTING_GUIDE.md](./TESTING_GUIDE.md) - Testing components
- [STYLING_GUIDE.md](./STYLING_GUIDE.md) - CSS conventions
- [NX_STRUCTURE.md](./NX_STRUCTURE.md) - Project organization
