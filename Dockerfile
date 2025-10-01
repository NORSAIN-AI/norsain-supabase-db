FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application files
COPY server.js ./

# Expose WebSocket port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "const ws = require('ws'); const client = new ws.WebSocket('ws://localhost:8080'); client.on('open', () => { client.close(); process.exit(0); }); client.on('error', () => process.exit(1));"

# Run the server
CMD ["node", "server.js"]
