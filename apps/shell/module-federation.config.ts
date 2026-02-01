import { ModuleFederationConfig } from '@nx/module-federation';

/**
 * Module Federation configuration for the shell (host) application.
 *
 * Note: The actual remote URLs are configured in webpack.config.ts
 * based on the environment (development vs production).
 */
const config: ModuleFederationConfig = {
  name: 'shell',
  remotes: ['products', 'product-detail'],
};

export default config;
