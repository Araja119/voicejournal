FROM node:20-alpine AS builder

RUN apk add --no-cache openssl

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./
COPY prisma ./prisma/

# Install all dependencies (including dev for build)
RUN npm ci

# Generate Prisma client
RUN npx prisma generate

# Copy source and build
COPY tsconfig.json ./
COPY src ./src/
RUN npm run build

# Production stage
FROM node:20-alpine AS runner

RUN apk add --no-cache openssl

WORKDIR /app

# Copy package files and install production dependencies only
COPY package.json package-lock.json ./
COPY prisma ./prisma/
RUN npm ci --omit=dev

# Generate Prisma client in production image
RUN npx prisma generate

# Copy built files from builder
COPY --from=builder /app/dist ./dist/

# Railway injects PORT env var
EXPOSE ${PORT:-3000}

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT:-3000}/health || exit 1

# Run migrations and start server
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/index.js"]
