const express = require('express');
const wppconnect = require('@wppconnect-team/wppconnect');

const app = express();
app.use(express.json());

let client = null;

// Initialize WhatsApp client
async function initializeClient() {
  try {
    client = await wppconnect.create({
      session: 'birthday-bot',
      catchQR: (base64Qr, asciiQR) => {
        console.log('QR Code:', asciiQR);
      },
      statusFind: (statusSession, session) => {
        console.log('Status Session:', statusSession);
        console.log('Session name:', session);
      },
      headless: true,
      devtools: false,
    });
    
    console.log('✅ WhatsApp client initialized successfully');
    return client;
  } catch (error) {
    console.error('❌ Error initializing client:', error);
    throw error;
  }
}

// Initialize on startup
initializeClient().catch(console.error);

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: client ? 'connected' : 'disconnected',
    service: 'wppconnect-bot',
    timestamp: new Date().toISOString()
  });
});

// Get all WhatsApp groups
app.get('/groups', async (req, res) => {
  try {
    if (!client) {
      return res.status(503).json({ error: 'Client not initialized', groups: [] });
    }

    const chats = await client.getAllChats();
    const groups = chats
      .filter(chat => chat.isGroup)
      .map(group => ({
        id: group.id._serialized,
        name: group.name,
        participants: group.groupMetadata?.participants?.length || 0
      }));

    res.json({ groups });
  } catch (error) {
    console.error('Error fetching groups:', error);
    res.status(500).json({ error: error.message, groups: [] });
  }
});

// Send message
app.post('/send', async (req, res) => {
  try {
    const { group, message } = req.body;

    if (!client) {
      return res.status(503).json({ error: 'Client not initialized' });
    }

    if (!group || !message) {
      return res.status(400).json({ error: 'group and message are required' });
    }

    // Find group by name
    const chats = await client.getAllChats();
    const targetGroup = chats.find(chat => 
      chat.isGroup && chat.name.toLowerCase() === group.toLowerCase()
    );

    if (!targetGroup) {
      return res.status(404).json({ error: `Group "${group}" not found` });
    }

    await client.sendText(targetGroup.id._serialized, message);

    res.json({
      success: true,
      group: targetGroup.name,
      message: 'Message sent successfully'
    });
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3005;
app.listen(PORT, () => {
  console.log(`🚀 wppconnect server running on port ${PORT}`);
});
