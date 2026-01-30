import { ModuleFederationConfig } from '@nx/module-federation';

const isProd = process.env['NODE_ENV'] === 'production';
const PROD_DOMAIN = process.env['PROD_DOMAIN'] || 'https://ecommerce.veeracs.info';

const config: ModuleFederationConfig = {
  name: 'shell',
  remotes: isProd
    ? [
        ['products', `${PROD_DOMAIN}/remotes/products/`],
        ['product-detail', `${PROD_DOMAIN}/remotes/product-detail/`],
      ]
    : [
        ['products', 'http://localhost:4201/'],
        ['product-detail', 'http://localhost:4202/'],
      ],
};

/**
 * Nx requires a default export of the config to allow correct resolution of the module federation graph.
 */
export default config;
