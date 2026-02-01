import { composePlugins, withNx } from '@nx/webpack';
import { withReact } from '@nx/react';
import { withModuleFederation } from '@nx/module-federation/webpack';

import baseConfig from './module-federation.config';

const config = {
  ...baseConfig,
};

export default composePlugins(
  withNx(),
  withReact(),
  withModuleFederation(config, { dts: false }),
  (config) => {
    // Ensure Safari-compatible output
    if (config.output) {
      config.output.chunkLoadingGlobal = 'webpackChunkproducts';
      config.output.uniqueName = 'products';
    }

    // Ensure proper target for Safari compatibility
    config.target = 'web';

    return config;
  }
);
