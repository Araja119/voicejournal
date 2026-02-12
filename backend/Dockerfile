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

RUN apk add --no-cache openssl netcat-openbsd

WORKDIR /app

# Copy package files and install production dependencies only
COPY package.json package-lock.json ./
COPY prisma ./prisma/
RUN npm ci --omit=dev

# Generate Prisma client in production image
RUN npx prisma generate

# Copy built files from builder
COPY --from=builder /app/dist ./dist/

# Copy startup script
COPY start.sh ./
RUN chmod +x start.sh

# Railway injects PORT env var
EXPOSE ${PORT:-3000}

# Health check - give more time for startup
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT:-3000}/health || exit 1

# Run startup script (waits for DB, runs migrations, starts server)
CMD ["./start.sh"]
