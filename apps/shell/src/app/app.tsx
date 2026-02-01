import { lazy, Suspense } from 'react';
import { Route, Routes, Navigate } from 'react-router-dom';
import { LoadingSpinner } from '@org/shop-shared-ui';
import { ErrorBoundary } from './ErrorBoundary';
import logo from '../assets/nucart-logo.svg';
import './app.css';

// Federated remotes - loaded at runtime from remote apps
// Enhanced error handling for mobile Safari compatibility
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
                  <ErrorBoundary
                    fallback={
                      <div style={{ padding: '20px', textAlign: 'center' }}>
                        Failed to load products
                      </div>
                    }
                  >
                    <ProductList />
                  </ErrorBoundary>
                }
              />
              <Route
                path="/products/:id"
                element={
                  <ErrorBoundary
                    fallback={
                      <div style={{ padding: '20px', textAlign: 'center' }}>
                        Failed to load product detail
                      </div>
                    }
                  >
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
