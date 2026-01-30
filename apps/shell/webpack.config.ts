import { composePlugins, withNx } from '@nx/webpack';
import { withReact } from '@nx/react';
import { withModuleFederation } from '@nx/module-federation/webpack';
import { ModuleFederationConfig } from '@nx/module-federation';

const isProd = process.env['NODE_ENV'] === 'production';
const PROD_DOMAIN = process.env['PROD_DOMAIN'] || 'https://ecommerce.veeracs.info';

// Configure remotes based on environment
// In production: use deployed URLs
// In development: use local dev servers (handled by nx serve)
const config: ModuleFederationConfig = {
  name: 'shell',
  remotes: isProd
    ? [
        ['products', `${PROD_DOMAIN}/remotes/products/remoteEntry.js`],
        ['product-detail', `${PROD_DOMAIN}/remotes/product-detail/remoteEntry.js`],
      ]
    : [
        ['products', 'http://localhost:4201/remoteEntry.js'],
        ['product-detail', 'http://localhost:4202/remoteEntry.js'],
      ],
};

export default composePlugins(
  withNx(),
  withReact(),
  withModuleFederation(config, { dts: false })
);
