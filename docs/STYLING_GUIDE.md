# Styling Guide

This document covers CSS conventions, patterns, and best practices used in this project.

## Table of Contents

- [Overview](#overview)
- [CSS Modules](#css-modules)
- [Naming Conventions](#naming-conventions)
- [Layout Patterns](#layout-patterns)
- [Responsive Design](#responsive-design)
- [CSS Variables](#css-variables)
- [Common Patterns](#common-patterns)
- [Accessibility](#accessibility)

---

## Overview

This project uses **CSS Modules** for component styling, providing:

- **Scoped styles** - No global namespace pollution
- **Explicit dependencies** - Import what you use
- **Dead code elimination** - Unused styles removed
- **Type safety** - TypeScript knows available classes

---

## CSS Modules

### Basic Usage

```tsx
// product-card.tsx
import styles from './product-card.module.css';

export function ProductCard({ name, price }: Props) {
  return (
    <article className={styles.card}>
      <h3 className={styles.title}>{name}</h3>
      <p className={styles.price}>${price}</p>
    </article>
  );
}
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
  margin: 0 0 8px;
}

.price {
  color: #2e7d32;
  font-weight: bold;
}
```

### Multiple Classes

```tsx
// Multiple static classes
<div className={`${styles.card} ${styles.featured}`}>

// Conditional classes
<div className={`${styles.card} ${isActive ? styles.active : ''}`}>

// Template literal
<div className={[styles.card, isActive && styles.active].filter(Boolean).join(' ')}>
```

### Composition

```css
/* Compose from another class */
.cardFeatured {
  composes: card;
  border-color: #1976d2;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

/* Compose from another file */
.button {
  composes: baseButton from '../shared/buttons.module.css';
  background: #1976d2;
}
```

---

## Naming Conventions

### Class Names

| Convention | Example | Use Case |
|------------|---------|----------|
| `camelCase` | `.productCard` | Standard class name |
| `elementName` | `.title`, `.price` | Child elements |
| `stateName` | `.isActive`, `.isLoading` | State modifiers |
| `variantName` | `.primary`, `.secondary` | Variants |

### Examples

```css
/* Component root */
.card { }

/* Child elements */
.cardImage { }
.cardTitle { }
.cardPrice { }
.cardActions { }

/* States */
.isActive { }
.isDisabled { }
.isLoading { }

/* Variants */
.cardFeatured { }
.cardCompact { }
```

### File Names

```
component-name.module.css    # Component styles
component-name.module.scss   # If using Sass
```

---

## Layout Patterns

### Flexbox Container

```css
/* Row layout */
.row {
  display: flex;
  flex-direction: row;
  gap: 16px;
}

/* Column layout */
.column {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

/* Center content */
.center {
  display: flex;
  justify-content: center;
  align-items: center;
}

/* Space between */
.spaceBetween {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
```

### Grid Layout

```css
/* Product grid */
.productGrid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 24px;
}

/* Fixed columns */
.threeColumn {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}
```

### Page Layout

```css
/* Full page layout */
.pageLayout {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.header {
  flex-shrink: 0;
}

.main {
  flex: 1;
  padding: 24px;
}

.footer {
  flex-shrink: 0;
}
```

---

## Responsive Design

### Breakpoints

```css
/* Mobile first approach */
.container {
  padding: 16px;
}

/* Tablet (768px+) */
@media (min-width: 768px) {
  .container {
    padding: 24px;
  }
}

/* Desktop (1024px+) */
@media (min-width: 1024px) {
  .container {
    padding: 32px;
    max-width: 1200px;
    margin: 0 auto;
  }
}

/* Large desktop (1440px+) */
@media (min-width: 1440px) {
  .container {
    max-width: 1400px;
  }
}
```

### Responsive Grid

```css
.productGrid {
  display: grid;
  gap: 16px;
  
  /* Mobile: 1 column */
  grid-template-columns: 1fr;
}

@media (min-width: 640px) {
  .productGrid {
    /* Tablet: 2 columns */
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (min-width: 1024px) {
  .productGrid {
    /* Desktop: 3-4 columns */
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 24px;
  }
}
```

### Responsive Typography

```css
.title {
  font-size: 1.5rem;
}

@media (min-width: 768px) {
  .title {
    font-size: 2rem;
  }
}

/* Or use clamp for fluid typography */
.title {
  font-size: clamp(1.5rem, 4vw, 2.5rem);
}
```

---

## CSS Variables

### Global Variables

```css
/* styles.css (global) */
:root {
  /* Colors */
  --color-primary: #1976d2;
  --color-primary-dark: #1565c0;
  --color-secondary: #dc004e;
  --color-success: #2e7d32;
  --color-error: #d32f2f;
  --color-warning: #ed6c02;
  
  /* Text colors */
  --color-text-primary: #212121;
  --color-text-secondary: #757575;
  --color-text-disabled: #9e9e9e;
  
  /* Background colors */
  --color-bg-primary: #ffffff;
  --color-bg-secondary: #f5f5f5;
  --color-bg-paper: #ffffff;
  
  /* Borders */
  --color-border: #e0e0e0;
  --border-radius-sm: 4px;
  --border-radius-md: 8px;
  --border-radius-lg: 16px;
  
  /* Spacing */
  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --spacing-lg: 24px;
  --spacing-xl: 32px;
  
  /* Typography */
  --font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  --font-size-sm: 0.875rem;
  --font-size-md: 1rem;
  --font-size-lg: 1.25rem;
  --font-size-xl: 1.5rem;
  
  /* Shadows */
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);
  --shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1);
  
  /* Transitions */
  --transition-fast: 150ms ease;
  --transition-normal: 250ms ease;
  --transition-slow: 350ms ease;
}
```

### Using Variables

```css
.card {
  background: var(--color-bg-paper);
  border: 1px solid var(--color-border);
  border-radius: var(--border-radius-md);
  padding: var(--spacing-md);
  box-shadow: var(--shadow-sm);
  transition: box-shadow var(--transition-normal);
}

.card:hover {
  box-shadow: var(--shadow-md);
}

.button {
  background: var(--color-primary);
  color: white;
  padding: var(--spacing-sm) var(--spacing-md);
  border-radius: var(--border-radius-sm);
}

.button:hover {
  background: var(--color-primary-dark);
}
```

### Dark Mode (Future)

```css
@media (prefers-color-scheme: dark) {
  :root {
    --color-text-primary: #ffffff;
    --color-bg-primary: #121212;
    --color-bg-paper: #1e1e1e;
    --color-border: #333333;
  }
}
```

---

## Common Patterns

### Card Component

```css
.card {
  background: var(--color-bg-paper);
  border: 1px solid var(--color-border);
  border-radius: var(--border-radius-md);
  overflow: hidden;
  transition: box-shadow var(--transition-normal);
}

.card:hover {
  box-shadow: var(--shadow-md);
}

.cardImage {
  width: 100%;
  height: 200px;
  object-fit: cover;
}

.cardContent {
  padding: var(--spacing-md);
}

.cardTitle {
  font-size: var(--font-size-lg);
  margin: 0 0 var(--spacing-sm);
}

.cardActions {
  padding: var(--spacing-sm) var(--spacing-md);
  border-top: 1px solid var(--color-border);
  display: flex;
  justify-content: flex-end;
  gap: var(--spacing-sm);
}
```

### Button Styles

```css
.button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--spacing-sm);
  padding: var(--spacing-sm) var(--spacing-md);
  border: none;
  border-radius: var(--border-radius-sm);
  font-size: var(--font-size-md);
  font-weight: 500;
  cursor: pointer;
  transition: background var(--transition-fast);
}

.buttonPrimary {
  composes: button;
  background: var(--color-primary);
  color: white;
}

.buttonPrimary:hover {
  background: var(--color-primary-dark);
}

.buttonSecondary {
  composes: button;
  background: transparent;
  border: 1px solid var(--color-primary);
  color: var(--color-primary);
}

.buttonDisabled {
  opacity: 0.5;
  cursor: not-allowed;
}
```

### Loading Spinner

```css
.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid var(--color-border);
  border-top-color: var(--color-primary);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.spinnerContainer {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 200px;
}
```

### Form Inputs

```css
.input {
  width: 100%;
  padding: var(--spacing-sm) var(--spacing-md);
  border: 1px solid var(--color-border);
  border-radius: var(--border-radius-sm);
  font-size: var(--font-size-md);
  transition: border-color var(--transition-fast);
}

.input:focus {
  outline: none;
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px rgba(25, 118, 210, 0.1);
}

.input::placeholder {
  color: var(--color-text-disabled);
}

.inputError {
  border-color: var(--color-error);
}

.inputLabel {
  display: block;
  margin-bottom: var(--spacing-xs);
  font-weight: 500;
  color: var(--color-text-secondary);
}

.inputHelp {
  margin-top: var(--spacing-xs);
  font-size: var(--font-size-sm);
  color: var(--color-text-secondary);
}

.inputErrorMessage {
  composes: inputHelp;
  color: var(--color-error);
}
```

---

## Accessibility

### Focus States

```css
/* Always visible focus for keyboard users */
.button:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}

/* Remove outline for mouse users */
.button:focus:not(:focus-visible) {
  outline: none;
}

/* Custom focus ring */
.card:focus-visible {
  outline: none;
  box-shadow: 0 0 0 3px var(--color-primary);
}
```

### Reduced Motion

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

### High Contrast

```css
@media (prefers-contrast: high) {
  .button {
    border: 2px solid currentColor;
  }
  
  .card {
    border-width: 2px;
  }
}
```

### Screen Reader Only

```css
.srOnly {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
```

---

## Do's and Don'ts

### Do's

| Practice | Reason |
|----------|--------|
| Use CSS variables | Consistent theming |
| Mobile-first breakpoints | Progressive enhancement |
| Use `rem` for font sizes | Respects user preferences |
| Add focus styles | Keyboard accessibility |
| Use semantic class names | Maintainable code |

### Don'ts

| Anti-Pattern | Problem |
|--------------|---------|
| `!important` | Specificity wars |
| Deep nesting | Hard to override |
| Magic numbers | Hard to maintain |
| ID selectors | Too specific |
| Inline styles | Can't reuse, override issues |

---

## Related Documentation

- [REACT_PATTERNS.md](./REACT_PATTERNS.md) - Component patterns
- [CONTRIBUTING.md](./CONTRIBUTING.md) - Code standards
