# Base image
FROM node:20-slim

# Set working directory
WORKDIR /app

# Copy package files first to leverage Docker cache
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy the rest of the code
COPY . .

# Expose the port used by your express app
EXPOSE 3005

# Add tini for proper signal handling and process management
RUN apt-get update && apt-get install -y tini

# Use tini as entrypoint to handle signals properly
ENTRYPOINT ["/usr/bin/tini", "--"]

# Start the bot with a script that keeps it running
CMD ["node", "-e", "process.on('uncaughtException', (err) => console.error('Uncaught exception:', err)); process.on('unhandledRejection', (err) => console.error('Unhandled rejection:', err)); require('./index.js');"]
