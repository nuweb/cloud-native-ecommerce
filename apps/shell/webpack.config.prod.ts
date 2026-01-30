import { composePlugins, withNx } from '@nx/webpack';
import { withReact } from '@nx/react';
import { withModuleFederation } from '@nx/module-federation/webpack';
import { ModuleFederationConfig } from '@nx/module-federation';

// Production module federation config
const PROD_DOMAIN = process.env['PROD_DOMAIN'] || 'https://ecommerce.veeracs.info';

const config: ModuleFederationConfig = {
  name: 'shell',
  remotes: [
    ['products', `${PROD_DOMAIN}/remotes/products/`],
    ['product-detail', `${PROD_DOMAIN}/remotes/product-detail/`],
  ],
};

export default composePlugins(
  withNx(),
  withReact(),
  withModuleFederation(config, { dts: false })
);
