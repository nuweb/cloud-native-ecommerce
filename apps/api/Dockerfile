# =============================================================================
# API Dockerfile
# Multi-stage build for minimal production image
# =============================================================================

# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Copy package files first for caching
COPY package.json pnpm-workspace.yaml ./
COPY pnpm-lock.yaml* ./
COPY apps/api/package.json ./apps/api/
COPY libs/api/products/package.json ./libs/api/products/
COPY libs/shared/models/package.json ./libs/shared/models/

# Install dependencies
RUN pnpm install

# Copy source code
COPY . .

# Build the API
RUN npx nx build api --configuration=production

# Debug: List the dist directory structure
RUN ls -la dist/ && ls -la dist/apps/ && ls -la dist/apps/api/ || true

# Stage 2: Production
FROM node:20-alpine AS runner

WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 api

# Copy built application - the API outputs to dist/apps/api
COPY --from=builder /app/dist/apps/api ./
COPY --from=builder /app/node_modules ./node_modules

# Set ownership
RUN chown -R api:nodejs /app

USER api

# Expose port
EXPOSE 3333

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3333/api/products || exit 1

# Start the application
CMD ["node", "main.js"]
