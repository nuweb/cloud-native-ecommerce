/**
 * Application configuration
 * API_URL can be overridden by setting VITE_API_URL or NX_API_URL environment variable
 */

// Check for environment variables (works with both Vite and Webpack)
const getEnvVar = (key: string): string | undefined => {
  // Vite environment variables
  if (typeof import.meta !== 'undefined' && import.meta.env) {
    return (import.meta.env as Record<string, string>)[key];
  }
  // Webpack/Node environment variables
  if (typeof process !== 'undefined' && process.env) {
    return process.env[key];
  }
  return undefined;
};

// Determine API URL based on environment
const getApiUrl = (): string => {
  // Check for explicit environment variable override
  const envApiUrl = getEnvVar('VITE_API_URL') || getEnvVar('NX_API_URL');
  if (envApiUrl) {
    return envApiUrl;
  }

  // Production detection
  const isProd =
    getEnvVar('NODE_ENV') === 'production' ||
    getEnvVar('VITE_MODE') === 'production' ||
    (typeof window !== 'undefined' &&
      window.location.hostname !== 'localhost');

  if (isProd) {
    // Production API URL
    return 'https://api.veeracs.info/api';
  }

  // Development API URL
  return 'http://localhost:3333/api';
};

export const config = {
  apiUrl: getApiUrl(),
};

export default config;
