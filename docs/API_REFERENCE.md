# API Reference

This document provides the complete API reference for the backend service.

## Table of Contents

- [Overview](#overview)
- [Base URL](#base-url)
- [Authentication](#authentication)
- [Endpoints](#endpoints)
- [Data Models](#data-models)
- [Error Handling](#error-handling)
- [Examples](#examples)

---

## Overview

The API is a RESTful service built with Express.js that provides product data for the e-commerce platform.

| Property     | Value              |
| ------------ | ------------------ |
| **Protocol** | HTTPS              |
| **Format**   | JSON               |
| **Port**     | 3333 (development) |

---

## Base URL

| Environment     | URL                                                 |
| --------------- | --------------------------------------------------- |
| **Development** | `http://localhost:3333/api`                         |
| **Production**  | `https://vpw7ds8tch.us-east-1.awsapprunner.com/api` |

---

## Authentication

Currently, the API is public and does not require authentication.

Future authentication will use JWT tokens:

```http
Authorization: Bearer <token>
```

---

## Endpoints

### Products

#### List Products

Retrieve a paginated list of products with optional filtering.

```http
GET /api/products
```

**Query Parameters**

| Parameter   | Type    | Default | Description                      |
| ----------- | ------- | ------- | -------------------------------- |
| `page`      | number  | 1       | Page number (1-indexed)          |
| `pageSize`  | number  | 12      | Items per page (max 100)         |
| `category`  | string  | -       | Filter by category               |
| `search`    | string  | -       | Search in name and description   |
| `inStock`   | boolean | -       | Filter by stock availability     |
| `minPrice`  | number  | -       | Minimum price filter             |
| `maxPrice`  | number  | -       | Maximum price filter             |
| `sortBy`    | string  | -       | Sort field (price, rating, name) |
| `sortOrder` | string  | asc     | Sort order (asc, desc)           |

**Response**

```json
{
  "items": [
    {
      "id": "1",
      "name": "Wireless Bluetooth Headphones",
      "description": "Premium noise-canceling headphones...",
      "price": 149.99,
      "category": "Electronics",
      "imageUrl": "https://images.unsplash.com/...",
      "inStock": true,
      "rating": 4.5,
      "reviewCount": 1284
    }
  ],
  "totalCount": 50,
  "page": 1,
  "pageSize": 12,
  "totalPages": 5
}
```

**Example Request**

```bash
curl "https://api.example.com/api/products?category=Electronics&page=1&pageSize=10"
```

---

#### Get Product by ID

Retrieve a single product by its ID.

```http
GET /api/products/:id
```

**Path Parameters**

| Parameter | Type   | Description |
| --------- | ------ | ----------- |
| `id`      | string | Product ID  |

**Response**

```json
{
  "id": "1",
  "name": "Wireless Bluetooth Headphones",
  "description": "Premium noise-canceling headphones with 30-hour battery life and crystal-clear sound quality.",
  "price": 149.99,
  "category": "Electronics",
  "imageUrl": "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500",
  "inStock": true,
  "rating": 4.5,
  "reviewCount": 1284
}
```

**Error Response (404)**

```json
{
  "error": "Product not found",
  "statusCode": 404
}
```

**Example Request**

```bash
curl "https://api.example.com/api/products/1"
```

---

#### Get Categories

Retrieve all available product categories.

```http
GET /api/products/categories
```

**Response**

```json
["Electronics", "Clothing", "Home & Kitchen", "Sports & Outdoors", "Books"]
```

**Example Request**

```bash
curl "https://api.example.com/api/products/categories"
```

---

### Health Check

#### Health Status

Check if the API is running and healthy.

```http
GET /health
```

**Response**

```json
{
  "status": "healthy"
}
```

---

## Data Models

### Product

```typescript
interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  category: string;
  imageUrl: string;
  inStock: boolean;
  rating: number;
  reviewCount: number;
}
```

| Field         | Type    | Description          |
| ------------- | ------- | -------------------- |
| `id`          | string  | Unique identifier    |
| `name`        | string  | Product name         |
| `description` | string  | Product description  |
| `price`       | number  | Price in USD         |
| `category`    | string  | Product category     |
| `imageUrl`    | string  | Product image URL    |
| `inStock`     | boolean | Availability status  |
| `rating`      | number  | Average rating (0-5) |
| `reviewCount` | number  | Number of reviews    |

### PaginatedResponse

```typescript
interface PaginatedResponse<T> {
  items: T[];
  totalCount: number;
  page: number;
  pageSize: number;
  totalPages: number;
}
```

| Field        | Type   | Description                |
| ------------ | ------ | -------------------------- |
| `items`      | T[]    | Array of items             |
| `totalCount` | number | Total items matching query |
| `page`       | number | Current page number        |
| `pageSize`   | number | Items per page             |
| `totalPages` | number | Total number of pages      |

### ProductFilter

```typescript
interface ProductFilter {
  category?: string;
  search?: string;
  inStock?: boolean;
  minPrice?: number;
  maxPrice?: number;
  page?: number;
  pageSize?: number;
  sortBy?: 'price' | 'rating' | 'name';
  sortOrder?: 'asc' | 'desc';
}
```

---

## Error Handling

### Error Response Format

```typescript
interface ErrorResponse {
  error: string;
  statusCode: number;
  details?: string;
}
```

### HTTP Status Codes

| Code  | Meaning               | When                   |
| ----- | --------------------- | ---------------------- |
| `200` | OK                    | Successful request     |
| `400` | Bad Request           | Invalid parameters     |
| `404` | Not Found             | Resource doesn't exist |
| `500` | Internal Server Error | Server error           |

### Error Examples

**400 Bad Request**

```json
{
  "error": "Invalid page parameter",
  "statusCode": 400,
  "details": "Page must be a positive integer"
}
```

**404 Not Found**

```json
{
  "error": "Product not found",
  "statusCode": 404
}
```

**500 Internal Server Error**

```json
{
  "error": "Internal server error",
  "statusCode": 500
}
```

---

## Examples

### JavaScript/TypeScript (Fetch)

```typescript
// Fetch products
async function getProducts(filter?: ProductFilter): Promise<PaginatedResponse<Product>> {
  const params = new URLSearchParams();

  if (filter?.category) params.set('category', filter.category);
  if (filter?.search) params.set('search', filter.search);
  if (filter?.inStock !== undefined) params.set('inStock', String(filter.inStock));
  if (filter?.page) params.set('page', String(filter.page));
  if (filter?.pageSize) params.set('pageSize', String(filter.pageSize));

  const response = await fetch(`${API_URL}/products?${params}`);

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }

  return response.json();
}

// Fetch single product
async function getProduct(id: string): Promise<Product> {
  const response = await fetch(`${API_URL}/products/${id}`);

  if (!response.ok) {
    if (response.status === 404) {
      throw new Error('Product not found');
    }
    throw new Error(`HTTP error! status: ${response.status}`);
  }

  return response.json();
}

// Usage
const products = await getProducts({ category: 'Electronics', page: 1 });
const product = await getProduct('1');
```

### cURL Examples

```bash
# Get all products
curl -X GET "http://localhost:3333/api/products"

# Get products with filters
curl -X GET "http://localhost:3333/api/products?category=Electronics&inStock=true&page=1&pageSize=10"

# Search products
curl -X GET "http://localhost:3333/api/products?search=headphones"

# Get single product
curl -X GET "http://localhost:3333/api/products/1"

# Get categories
curl -X GET "http://localhost:3333/api/products/categories"

# Health check
curl -X GET "http://localhost:3333/health"
```

### React Hook Usage

```tsx
import { useProducts, useProduct } from '@org/shop-data';

// List products
function ProductList() {
  const { products, isLoading, error } = useProducts({
    filter: { category: 'Electronics' },
    page: 1,
    pageSize: 12,
  });

  if (isLoading) return <LoadingSpinner />;
  if (error) return <ErrorMessage message={error.message} />;

  return (
    <div>
      {products.map((product) => (
        <ProductCard key={product.id} {...product} />
      ))}
    </div>
  );
}

// Single product
function ProductDetail({ id }: { id: string }) {
  const { product, isLoading, error } = useProduct(id);

  if (isLoading) return <LoadingSpinner />;
  if (error) return <ErrorMessage message={error.message} />;
  if (!product) return <NotFound />;

  return <ProductDetailView product={product} />;
}
```

---

## Rate Limiting

Currently no rate limiting is implemented. Future implementation:

| Limit               | Value |
| ------------------- | ----- |
| Requests per minute | 100   |
| Requests per hour   | 1000  |

Rate limit headers:

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000
```

---

## CORS

The API allows cross-origin requests from the frontend domain:

| Environment | Allowed Origin                   |
| ----------- | -------------------------------- |
| Development | `http://localhost:4200`          |
| Production  | `https://ecommerce.veeracs.info` |

---

## Related Documentation

- [TECH_STACK.md](./TECH_STACK.md) - Technology overview
- [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - Deployment instructions
- [NX_STRUCTURE.md](./NX_STRUCTURE.md) - Project structure
