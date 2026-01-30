import { composePlugins, withNx } from '@nx/webpack';
import { withReact } from '@nx/react';
import { withModuleFederation } from '@nx/module-federation/webpack';
import { ModuleFederationConfig } from '@nx/module-federation';

const isProd = process.env['NODE_ENV'] === 'production';
const PROD_DOMAIN = process.env['PROD_DOMAIN'] || 'https://ecommerce.veeracs.info';

// Configure remotes based on environment
const config: ModuleFederationConfig = {
  name: 'shell',
  remotes: isProd
    ? {
        // Use object format with full URLs for production
        products: `products@${PROD_DOMAIN}/remotes/products/remoteEntry.js`,
        'product-detail': `product-detail@${PROD_DOMAIN}/remotes/product-detail/remoteEntry.js`,
      }
    : ['products', 'product-detail'], // Let nx serve handle dev remotes
};

export default composePlugins(
  withNx(),
  withReact(),
  withModuleFederation(config, { dts: false })
);
