import { lazy, Suspense } from 'react';
import { Route, Routes, Navigate } from 'react-router-dom';
import { LoadingSpinner } from '@org/shop-shared-ui';
import logo from '../assets/logo.svg';
import './app.css';

// Federated remotes - loaded at runtime from remote apps
const ProductList = lazy(() => import('products/Module').then((m) => ({ default: m.default })));
const ProductDetail = lazy(() => import('product-detail/Module').then((m) => ({ default: m.default })));

export function App() {
  return (
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
            <Route path="/products" element={<ProductList />} />
            <Route path="/products/:id" element={<ProductDetail />} />
            <Route path="*" element={<Navigate to="/products" replace />} />
          </Routes>
        </Suspense>
      </main>
    </div>
  );
}

export default App;
