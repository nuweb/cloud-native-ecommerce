/**
 * Application configuration
 * Detects environment at runtime to determine API URL
 */

// Determine API URL based on environment
const getApiUrl = (): string => {
  // Runtime detection - check if we're in a browser and on production domain
  if (typeof window !== 'undefined') {
    const hostname = window.location.hostname;
    if (hostname !== 'localhost' && hostname !== '127.0.0.1') {
      // Production - use App Runner URL directly (has valid SSL)
      return 'https://vpw7ds8tch.us-east-1.awsapprunner.com/api';
    }
  }

  // Development API URL
  return 'http://localhost:3333/api';
};

export const config = {
  apiUrl: getApiUrl(),
};

export default config;
