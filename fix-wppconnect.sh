#!/bin/bash

set -e

echo "🔧 Fixing wppconnect-bot..."
echo ""

cd /opt/whatsapp-birthday-lambda

# Create wppconnect-server directory if it doesn't exist
mkdir -p wppconnect-server

# 1. Create Dockerfile
echo "1. Creating wppconnect-server/Dockerfile..."
cat > wppconnect-server/Dockerfile << 'DOCKERFILE'
FROM node:18-slim

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    chromium \
    chromium-sandbox \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libgdk-pixbuf2.0-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    xdg-utils \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set Puppeteer to skip downloading Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Copy package files
COPY package*.json ./

# Install Node dependencies
RUN npm install

# Copy application files
COPY server.js ./

# Create tokens directory
RUN mkdir -p tokens

# Expose port
EXPOSE 3005

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:3005/health || exit 1

# Start server
CMD ["node", "server.js"]
DOCKERFILE
echo "✅ Dockerfile created"
echo ""

# 2. Create server.js
echo "2. Creating wppconnect-server/server.js..."
cat > wppconnect-server/server.js << 'SERVERJS'
const express = require('express');
const wppconnect = require('@wppconnect-team/wppconnect');

const app = express();
app.use(express.json());

let client = null;
let isConnected = false;

// Initialize WhatsApp client
async function initializeClient() {
  try {
    console.log('🔄 Initializing WhatsApp client...');
    
    client = await wppconnect.create({
      session: 'birthday-bot',
      catchQR: (base64Qr, asciiQR) => {
        console.log('📱 QR Code generated:');
        console.log(asciiQR);
        console.log('\nScan this QR code with WhatsApp to connect');
      },
      statusFind: (statusSession, session) => {
        console.log('📊 Status:', statusSession);
        console.log('📝 Session:', session);
        
        if (statusSession === 'isLogged') {
          isConnected = true;
          console.log('✅ WhatsApp connected successfully!');
        }
      },
      headless: true,
      devtools: false,
      useChrome: true,
      debug: false,
      logQR: true,
      browserArgs: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-accelerated-2d-canvas',
        '--no-first-run',
        '--no-zygote',
        '--disable-gpu'
      ]
    });
    
    console.log('✅ WhatsApp client initialized successfully');
    return client;
  } catch (error) {
    console.error('❌ Error initializing client:', error);
    throw error;
  }
}

// Initialize on startup
initializeClient().catch(err => {
  console.error('Failed to initialize:', err);
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: isConnected ? 'connected' : 'disconnected',
    service: 'wppconnect-bot',
    timestamp: new Date().toISOString(),
    hasClient: client !== null
  });
});

// Get all WhatsApp groups
app.get('/groups', async (req, res) => {
  try {
    if (!client) {
      return res.status(503).json({ 
        error: 'Client not initialized',
        groups: [] 
      });
    }

    if (!isConnected) {
      return res.status(503).json({ 
        error: 'WhatsApp not connected',
        groups: [] 
      });
    }

    console.log('📋 Fetching WhatsApp groups...');
    const chats = await client.getAllChats();
    
    const groups = chats
      .filter(chat => chat.isGroup)
      .map(group => ({
        id: group.id._serialized,
        name: group.name,
        participants: group.groupMetadata?.participants?.length || 0
      }));

    console.log(`✅ Found ${groups.length} groups`);
    res.json({ groups });
  } catch (error) {
    console.error('❌ Error fetching groups:', error);
    res.status(500).json({ 
      error: error.message,
      groups: [] 
    });
  }
});

// Send message to group
app.post('/send', async (req, res) => {
  try {
    const { group, message } = req.body;

    if (!client) {
      return res.status(503).json({ error: 'Client not initialized' });
    }

    if (!isConnected) {
      return res.status(503).json({ error: 'WhatsApp not connected' });
    }

    if (!group || !message) {
      return res.status(400).json({ error: 'group and message are required' });
    }

    console.log(`📤 Sending message to group: ${group}`);

    // Find group by name
    const chats = await client.getAllChats();
    const targetGroup = chats.find(chat => 
      chat.isGroup && chat.name.toLowerCase() === group.toLowerCase()
    );

    if (!targetGroup) {
      console.log(`❌ Group "${group}" not found`);
      return res.status(404).json({ error: `Group "${group}" not found` });
    }

    await client.sendText(targetGroup.id._serialized, message);
    console.log(`✅ Message sent to ${targetGroup.name}`);

    res.json({
      success: true,
      group: targetGroup.name,
      message: 'Message sent successfully'
    });
  } catch (error) {
    console.error('❌ Error sending message:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get connection status
app.get('/status', (req, res) => {
  res.json({
    connected: isConnected,
    hasClient: client !== null,
    timestamp: new Date().toISOString()
  });
});

const PORT = process.env.PORT || 3005;
app.listen(PORT, () => {
  console.log('================================================');
  console.log(`🚀 wppconnect server running on port ${PORT}`);
  console.log('================================================');
  console.log('Endpoints:');
  console.log(`  Health:  http://localhost:${PORT}/health`);
  console.log(`  Groups:  http://localhost:${PORT}/groups`);
  console.log(`  Send:    POST http://localhost:${PORT}/send`);
  console.log(`  Status:  http://localhost:${PORT}/status`);
  console.log('================================================');
});
SERVERJS
echo "✅ server.js created"
echo ""

# 3. Create package.json
echo "3. Creating wppconnect-server/package.json..."
cat > wppconnect-server/package.json << 'PACKAGEJSON'
{
  "name": "wppconnect-birthday-bot",
  "version": "1.0.0",
  "description": "WhatsApp bot using wppconnect",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "keywords": ["whatsapp", "bot", "wppconnect"],
  "author": "",
  "license": "MIT",
  "dependencies": {
    "@wppconnect-team/wppconnect": "^1.30.1",
    "express": "^4.18.2"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
PACKAGEJSON
echo "✅ package.json created"
echo ""

# 4. Create .dockerignore for wppconnect
echo "4. Creating wppconnect-server/.dockerignore..."
cat > wppconnect-server/.dockerignore << 'DOCKERIGNORE'
node_modules
tokens
*.log
.git
DOCKERIGNORE
echo "✅ .dockerignore created"
echo ""

echo "✅ All wppconnect files created!"
echo ""
echo "Files created:"
ls -la wppconnect-server/
