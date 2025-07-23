global.crypto = require('crypto')
const { default: makeWASocket, useMultiFileAuthState, DisconnectReason } = require('@whiskeysockets/baileys')
const { Boom } = require('@hapi/boom')
const express = require('express')
const qrcode = require('qrcode-terminal')

const PORT = process.env.PORT || 3005
let sock = null
let isReady = false
let serverStarted = false

// Prevent crash on unhandled errors
process.on('uncaughtException', (err) => {
    console.error('Uncaught exception:', err)
})

process.on('unhandledRejection', (err) => {
    console.error('Unhandled rejection:', err)
})

// Helper function to normalize group names for better matching
function normalizeGroupName(name) {
    return name.toLowerCase().replace(/_/g, ' ').trim();
}

async function startSock() {
    const { state, saveCreds } = await useMultiFileAuthState('./auth')
    sock = makeWASocket({
        auth: state,
        printQRInTerminal: true
    })

    sock.ev.on('creds.update', saveCreds)

    sock.ev.on('connection.update', ({ connection, lastDisconnect, qr }) => {
        if (qr) qrcode.generate(qr, { small: true })
        if (connection === 'close') {
            isReady = false
            const shouldReconnect = (lastDisconnect?.error instanceof Boom &&
                lastDisconnect.error.output.statusCode !== DisconnectReason.loggedOut)
            console.log('❌ Connection closed. Reconnecting...', shouldReconnect)
            if (shouldReconnect) startSock()
        } else if (connection === 'open') {
            console.log('✅ Connected to WhatsApp')
            isReady = true
        }
    })

    const app = express()
    app.use(express.json())

    // Health check
    app.get('/health', (req, res) => {
        res.json({ status: 'ok', ready: isReady })
    })

    // Send message to group with improved group name matching
    app.post('/send', async (req, res) => {
        if (!isReady) {
            return res.status(428).json({ error: 'WhatsApp connection not ready. Try again shortly.' })
        }

        const { group, message } = req.body
        if (!group || !message) {
            return res.status(400).json({ error: 'group and message required' })
        }

        try {
            const chats = await sock.groupFetchAllParticipating()
            const normalizedSearchName = normalizeGroupName(group);
            
            // Try different matching strategies
            let groupMatch = null;
            
            // First try exact match (case-insensitive)
            groupMatch = Object.values(chats).find(g => 
                normalizeGroupName(g.subject) === normalizedSearchName
            );
            
            // If no exact match, try contains match
            if (!groupMatch) {
                groupMatch = Object.values(chats).find(g => 
                    normalizeGroupName(g.subject).includes(normalizedSearchName) ||
                    normalizedSearchName.includes(normalizeGroupName(g.subject))
                );
            }
            
            if (!groupMatch) {
                console.log(`Group "${group}" not found. Available groups:`, 
                    Object.values(chats)
                        .filter(g => g.subject)
                        .map(g => g.subject)
                );
                return res.status(404).json({ 
                    error: `Group "${group}" not found`,
                    availableGroups: Object.values(chats)
                        .filter(g => g.subject)
                        .map(g => g.subject)
                });
            }

            const result = await sock.sendMessage(groupMatch.id, { text: message });
            console.log(`✅ Sent message to "${groupMatch.subject}" (${groupMatch.id})`);
            return res.json({ 
                success: true, 
                group: groupMatch.subject,
                groupId: groupMatch.id
            });
        } catch (err) {
            console.error('❌ Error sending message:', err);
            return res.status(500).json({ 
                error: 'Failed to send message', 
                details: err.message
            });
        }
    })

    // Status endpoint
    app.get('/status', (req, res) => {
        const isConnected = sock && sock.user && (sock.user.id !== undefined)
        res.json({
            connected: isConnected,
            user: isConnected ? sock.user : null,
            timestamp: new Date().toISOString()
        })
    })

    // List WhatsApp groups with detailed info
    app.get('/groups', async (req, res) => {
        try {
            if (!sock || !sock.user) {
                return res.status(503).json({ error: 'WhatsApp not connected' })
            }

            const chats = await sock.groupFetchAllParticipating()
            const groups = Object.entries(chats)
                .filter(([_, chat]) => chat.subject)
                .map(([id, chat]) => ({
                    id,
                    name: chat.subject,
                    normalized_name: normalizeGroupName(chat.subject),
                    participants: chat.participants?.length || 0
                }))

            console.log(`Found ${groups.length} WhatsApp groups`);
            res.json(groups)
        } catch (error) {
            console.error('❌ Error fetching groups:', error)
            res.status(500).json({ error: 'Failed to fetch groups' })
        }
    })

    // Test send message endpoint with detailed debugging
    app.post('/test-send', async (req, res) => {
        if (!isReady) {
            return res.status(428).json({ error: 'WhatsApp connection not ready. Try again shortly.' })
        }

        const { group } = req.body
        if (!group) {
            return res.status(400).json({ error: 'group parameter required' })
        }

        try {
            const chats = await sock.groupFetchAllParticipating()
            const normalizedSearchName = normalizeGroupName(group);
            
            console.log(`Looking for group: "${group}" (normalized: "${normalizedSearchName}")`);
            console.log(`Available groups:`, Object.values(chats)
                .filter(g => g.subject)
                .map(g => ({
                    name: g.subject,
                    normalized: normalizeGroupName(g.subject),
                    id: g.id
                }))
            );
            
            // Try different matching strategies
            let groupMatch = null;
            
            // First try exact match (case-insensitive)
            groupMatch = Object.values(chats).find(g => 
                normalizeGroupName(g.subject) === normalizedSearchName
            );
            
            // If no exact match, try contains match
            if (!groupMatch) {
                groupMatch = Object.values(chats).find(g => 
                    normalizeGroupName(g.subject).includes(normalizedSearchName) ||
                    normalizedSearchName.includes(normalizeGroupName(g.subject))
                );
            }
            
            if (!groupMatch) {
                return res.status(404).json({ 
                    error: `Group "${group}" not found`,
                    availableGroups: Object.values(chats)
                        .filter(g => g.subject)
                        .map(g => ({
                            name: g.subject, 
                            normalized: normalizeGroupName(g.subject)
                        }))
                });
            }

            // Construct test message
            const message = `Test message from API at ${new Date().toISOString()}`;
            
            // Send the message
            const result = await sock.sendMessage(groupMatch.id, { text: message });
            
            console.log(`✅ Test message sent to "${groupMatch.subject}" (${groupMatch.id})`);
            
            return res.json({
                success: true,
                message: 'Test message sent successfully',
                group: {
                    name: groupMatch.subject,
                    id: groupMatch.id,
                    normalized: normalizeGroupName(groupMatch.subject)
                }
            });
        } catch (error) {
            console.error('❌ Error sending test message:', error);
            return res.status(500).json({ 
                error: 'Failed to send test message', 
                details: error.message 
            });
        }
    });

    // Debug endpoint to dump group info
    app.get('/debug-groups', async (req, res) => {
        try {
            if (!sock || !sock.user) {
                return res.status(503).json({ error: 'WhatsApp not connected' })
            }

            const chats = await sock.groupFetchAllParticipating()
            const groupsInfo = {};
            
            for (const [id, chat] of Object.entries(chats)) {
                if (chat.subject) {
                    groupsInfo[id] = {
                        name: chat.subject,
                        normalized_name: normalizeGroupName(chat.subject),
                        participants: chat.participants?.length || 0,
                        creation_time: chat.creation || 'unknown'
                    };
                }
            }

            res.json({
                count: Object.keys(groupsInfo).length,
                groups: groupsInfo
            });
        } catch (error) {
            console.error('❌ Error in debug endpoint:', error);
            res.status(500).json({ error: 'Debug failed', details: error.message });
        }
    });

    if (!serverStarted) {
        app.listen(PORT, '0.0.0.0', () => {
            serverStarted = true
            console.log(`🌐 API running at http://0.0.0.0:${PORT}`)
        })
    }
}

// Start the bot and server
startSock()

// Heartbeat logger to keep process alive and observable
setInterval(() => {
    console.log(`🔄 Service heartbeat - WhatsApp connection ready: ${isReady}`)
}, 60000)
