const express = require('express');
const wppconnect = require('@wppconnect-team/wppconnect');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(express.json());

let client = null;

function saveQrPng(base64Qr) {
  const out = path.join(__dirname, 'qr-code.png');
  const b64 = base64Qr.replace(/^data:image\/png;base64,/, '');
  fs.writeFileSync(out, Buffer.from(b64, 'base64'));
  console.log(`📸 Saved QR to ${out}`);
}

async function start() {
  console.log('🔄 Initializing WhatsApp client...');
  client = await wppconnect.create({
    session: 'birthday-bot',
    logQR: true,
    autoClose: 600000, // 10 minutes
    waitForLogin: true,
    deviceName: 'Birthday Bot',
    useChrome: true,
    headless: true,
    browserArgs: ['--no-sandbox', '--disable-setuid-sandbox'],
    catchQR: (base64Qr, asciiQR /*, attempts, urlCode */) => {
      console.log(asciiQR);
      saveQrPng(base64Qr);
      console.log('📱 SCAN THIS QR CODE NOW:\n   http://localhost:3005/qr-code.png');
      console.log('You have 10 MINUTES to scan it!');
    }
  });

  console.log('✅ Client created. Waiting for authentication...');
}

app.get('/health', (_req, res) => {
  res.json({ ok: true, session: 'birthday-bot' });
});

app.get('/qr-code.png', (_req, res) => {
  const p = path.join(__dirname, 'qr-code.png');
  if (fs.existsSync(p)) {
    res.sendFile(p);
  } else {
    res.status(404).json({ error: 'QR not generated yet' });
  }
});

app.get('/groups', async (_req, res) => {
  try {
    const chats = await client.listChats();
    const groups = chats.filter(c => c.isGroup).map(c => ({ id: c.id._serialized, name: c.formattedTitle || c.name }));
    res.json(groups);
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

app.post('/send', async (req, res) => {
  try {
    const { group, message } = req.body || {};
    if (!group || !message) return res.status(400).json({ error: 'group and message required' });

    const chats = await client.listChats();
    const target = chats.find(c => c.isGroup && (c.formattedTitle === group || c.name === group));
    if (!target) return res.status(404).json({ error: `Group not found: ${group}` });

    await client.sendText(target.id._serialized, message);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

const PORT = process.env.PORT || 3005;
app.listen(PORT, () => console.log(`🚀 wppconnect server listening on ${PORT}`));

start().catch(err => {
  console.error('❌ Failed to initialize:', err);
  process.exit(1);
});
