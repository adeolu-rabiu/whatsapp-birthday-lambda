global.crypto = require('crypto')
const { default: makeWASocket, useMultiFileAuthState, DisconnectReason } = require('@whiskeysockets/baileys')
const { Boom } = require('@hapi/boom')
const express = require('express')
const qrcode = require('qrcode-terminal')

const PORT = process.env.PORT || 3005
let sock = null
let isReady = false
let isFullyConnected = false
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

// Add delay helper
function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function startSock() {
    const { state, saveCreds } = await useMultiFileAuthState('./auth')
    
    sock = makeWASocket({
        auth: state,
        printQRInTerminal: true,
        syncFullHistory: false,  // Reduce sync load
        markOnlineOnConnect: true
    })

    sock.ev.on('creds.update', saveCreds)
    
    sock.ev.on('connection.update', async ({ connection, lastDisconnect, qr }) => {
        if (qr) {
            qrcode.generate(qr, { small: true })
        }
        
        if (connection === 'close') {
            isReady = false
            isFullyConnected = false
            const shouldReconnect = (lastDisconnect?.error instanceof Boom &&
                lastDisconnect.error.output.statusCode !== DisconnectReason.loggedOut)
            console.log('❌ Connection closed. Reconnecting...', shouldReconnect)
            if (shouldReconnect) {
                await delay(5000) // Wait 5 seconds before reconnecting
                startSock()
            }
        } else if (connection === 'open') {
            console.log('✅ Connected to WhatsApp')
            isReady = true
            
            // Wait a bit for sessions to be fully established
            setTimeout(() => {
                isFullyConnected = true
                console.log('🚀 Fully connected and ready for messaging')
            }, 10000) // Wait 10 seconds for full initialization
        }
    })

    // Handle messaging updates
    sock.ev.on('messages.upsert', async ({ messages }) => {
        // Handle incoming messages if needed
    })

    // Start express server only once
    if (!serverStarted) {
        startExpressServer()
        serverStarted = true
    }
}

function startExpressServer() {
    const app = express()
    app.use(express.json())

    // Health check
    app.get('/health', (req, res) => {
        res.json({ 
            status: 'ok', 
            ready: isReady,
            fullyConnected: isFullyConnected
        })
    })

    // Status endpoint
    app.get('/status', (req, res) => {
        const user = sock?.user || null
        res.json({
            connected: isReady && isFullyConnected,
            user: user,
            timestamp: new Date().toISOString()
        })
    })

    // Groups endpoint
    app.get('/groups', async (req, res) => {
        if (!isFullyConnected || !sock) {
            return res.status(428).json({ 
                error: 'WhatsApp connection not fully ready. Try again shortly.' 
            })
        }

        try {
            const chats = await sock.groupFetchAllParticipating()
            const groups = Object.values(chats)
                .filter(g => g.subject)
                .map(g => ({
                    id: g.id,
                    name: g.subject,
                    normalized_name: normalizeGroupName(g.subject),
                    participants: g.participants ? g.participants.length : 0
                }))
            
            res.json(groups)
        } catch (error) {
            console.error('❌ Error fetching groups:', error)
            res.status(500).json({ 
                error: 'Failed to fetch groups', 
                details: error.message 
            })
        }
    })

    // Test send endpoint
    app.post('/test-send', async (req, res) => {
        if (!isFullyConnected || !sock) {
            return res.status(428).json({ 
                error: 'WhatsApp connection not fully ready. Try again shortly.' 
            })
        }

        const { group } = req.body
        if (!group) {
            return res.status(400).json({ error: 'group parameter required' })
        }

        try {
            const chats = await sock.groupFetchAllParticipating()
            const normalizedSearchName = normalizeGroupName(group)
            
            const availableGroups = Object.values(chats)
                .filter(g => g.subject)
                .map(g => ({
                    id: g.id,
                    name: g.subject,
                    normalized_name: normalizeGroupName(g.subject)
                }))

            const groupMatch = availableGroups.find(g =>
                g.normalized_name === normalizedSearchName ||
                g.normalized_name.includes(normalizedSearchName) ||
                normalizedSearchName.includes(g.normalized_name)
            )

            if (groupMatch) {
                res.json({
                    success: true,
                    group: groupMatch,
                    message: 'Group found and ready for messaging'
                })
            } else {
                res.status(404).json({
                    error: `Group "${group}" not found`,
                    availableGroups: availableGroups
                })
            }
        } catch (error) {
            console.error('❌ Error in test-send:', error)
            res.status(500).json({ 
                error: 'Failed to test send', 
                details: error.message 
            })
        }
    })

    // Send message to group with session establishment
    app.post('/send', async (req, res) => {
        if (!isFullyConnected || !sock) {
            return res.status(428).json({ 
                error: 'WhatsApp connection not fully ready. Try again shortly.' 
            })
        }

        const { group, message } = req.body
        if (!group || !message) {
            return res.status(400).json({ error: 'group and message required' })
        }

        try {
            // Get groups first
            const chats = await sock.groupFetchAllParticipating()
            const normalizedSearchName = normalizeGroupName(group)
            
            // Find the group
            let groupMatch = Object.values(chats).find(g =>
                normalizeGroupName(g.subject) === normalizedSearchName
            )
            
            if (!groupMatch) {
                groupMatch = Object.values(chats).find(g =>
                    normalizeGroupName(g.subject).includes(normalizedSearchName) ||
                    normalizedSearchName.includes(normalizeGroupName(g.subject))
                )
            }

            if (!groupMatch) {
                return res.status(404).json({
                    error: `Group "${group}" not found`,
                    availableGroups: Object.values(chats)
                        .filter(g => g.subject)
                        .map(g => ({ id: g.id, name: g.subject }))
                })
            }

            // Try to establish session by sending presence first
            try {
                await sock.sendPresenceUpdate('available', groupMatch.id)
                await delay(1000)
            } catch (presenceError) {
                console.log('⚠️ Could not send presence update:', presenceError.message)
            }

            // Try sending the message with session establishment
            let retryCount = 0
            const maxRetries = 3

            while (retryCount < maxRetries) {
                try {
                    // For groups with session issues, try fetching group metadata first
                    try {
                        await sock.groupMetadata(groupMatch.id)
                        await delay(500)
                    } catch (metaError) {
                        console.log('⚠️ Could not fetch group metadata:', metaError.message)
                    }

                    await sock.sendMessage(groupMatch.id, { text: message })
                    console.log(`✅ Message sent to ${groupMatch.subject}: ${message}`)
                    return res.json({ 
                        success: true, 
                        group: groupMatch.subject,
                        message: 'Message sent successfully'
                    })
                } catch (error) {
                    retryCount++
                    console.log(`⚠️ Send attempt ${retryCount} failed:`, error.message)
                    
                    if (error.message.includes('No sessions') && retryCount < maxRetries) {
                        console.log(`🔄 Attempting to establish session... (${retryCount}/${maxRetries})`)
                        
                        // Try different session establishment methods
                        try {
                            // Method 1: Send a read receipt to establish session
                            const lastMsg = await sock.fetchGroupMessages(groupMatch.id, 1)
                            if (lastMsg && lastMsg.length > 0) {
                                await sock.readMessages([lastMsg[0].key])
                            }
                        } catch (readError) {
                            console.log('⚠️ Could not send read receipt')
                        }

                        await delay(3000 * retryCount) // Longer delay for session establishment
                        continue
                    }
                    throw error
                }
            }

            throw new Error('Failed to send message after all retries')

        } catch (error) {
            console.error('❌ Error sending message:', error)
            res.status(500).json({ 
                error: 'Failed to send message', 
                details: error.message 
            })
        }
    })

    // Debug groups endpoint
    app.get('/debug-groups', async (req, res) => {
        if (!isFullyConnected || !sock) {
            return res.status(428).json({ 
                error: 'WhatsApp connection not fully ready' 
            })
        }

        try {
            const chats = await sock.groupFetchAllParticipating()
            const count = Object.keys(chats).length
            
            res.json({
                count: count,
                ready: isFullyConnected,
                timestamp: new Date().toISOString()
            })
        } catch (error) {
            res.status(500).json({ 
                error: 'Failed to debug groups', 
                details: error.message 
            })
        }
    })

    // Start heartbeat
    setInterval(() => {
        console.log(`🔄 Service heartbeat - WhatsApp connection ready: ${isFullyConnected}`)
    }, 30000)

    app.listen(PORT, '0.0.0.0', () => {
        console.log(`🌐 API running at http://0.0.0.0:${PORT}`)
    })
}

// Start the bot
startSock()
