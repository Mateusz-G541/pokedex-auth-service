# Use Node.js 18 LTS
FROM node:18-alpine

# Install OpenSSL for key generation
RUN apk add --no-cache openssl

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Generate RSA keys if they don't exist
RUN if [ ! -f keys/private.pem ]; then \
    mkdir -p keys && \
    openssl genrsa -out keys/private.pem 2048 && \
    openssl rsa -in keys/private.pem -pubout -out keys/public.pem && \
    chmod 600 keys/private.pem && \
    chmod 644 keys/public.pem; \
    fi

# Generate Prisma client
RUN npx prisma generate

# Build TypeScript
RUN npm run build

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

# Start the application
CMD ["npm", "start"]
