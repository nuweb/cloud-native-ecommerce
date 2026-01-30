import { composePlugins, withNx } from '@nx/webpack';
import { withReact } from '@nx/react';
import { withModuleFederation } from '@nx/module-federation/webpack';
import { ModuleFederationConfig, Remotes } from '@nx/module-federation';

const isProd = process.env['NODE_ENV'] === 'production';
const PROD_DOMAIN = process.env['PROD_DOMAIN'] || 'https://ecommerce.veeracs.info';

// Configure remotes based on environment
// Use tuple format: [remoteName, remoteUrl]
const prodRemotes: Remotes = [
  ['products', `${PROD_DOMAIN}/remotes/products/remoteEntry.js`],
  ['product-detail', `${PROD_DOMAIN}/remotes/product-detail/remoteEntry.js`],
];

const devRemotes: Remotes = [
  ['products', 'http://localhost:4201/remoteEntry.js'],
  ['product-detail', 'http://localhost:4202/remoteEntry.js'],
];

const config: ModuleFederationConfig = {
  name: 'shell',
  remotes: isProd ? prodRemotes : devRemotes,
};

export default composePlugins(
  withNx(),
  withReact(),
  withModuleFederation(config, { dts: false })
);
