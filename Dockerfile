########################################
# Builder stage: install dev deps and build
########################################
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package manifests and install ALL deps (incl. dev)
COPY package*.json ./
RUN npm ci

# Copy the full source
COPY . .

# Generate Prisma client (uses dev deps here)
RUN npx prisma generate

# Build TypeScript
RUN npm run build

########################################
# Final stage: production image
########################################
FROM node:18-alpine

WORKDIR /app

# Install OpenSSL runtime (required by Prisma engine on Alpine)
RUN apk add --no-cache openssl

# Copy package manifests and install production deps
COPY package*.json ./
RUN npm ci --only=production

# Copy built app and necessary runtime assets from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/scripts/gen-keys.js ./scripts/gen-keys.js

# Ensure scripts dir exists (in case not present)
RUN mkdir -p scripts

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S authuser -u 1001

# Change ownership of the app directory
RUN chown -R authuser:nodejs /app

# Switch to non-root user
USER authuser

# Expose port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:4000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Start the application: generate keys if missing, apply DB migrations, then start server
CMD ["sh", "-c", "node scripts/gen-keys.js && npx prisma migrate deploy && node dist/index.js"]
