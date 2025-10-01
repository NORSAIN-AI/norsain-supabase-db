import { WebSocketServer } from 'ws';
import pkg from 'pg';
const { Client } = pkg;
import dotenv from 'dotenv';

dotenv.config();

const POSTGRES_CONFIG = {
  host: process.env.POSTGRES_HOST || 'localhost',
  port: parseInt(process.env.POSTGRES_PORT || '5432'),
  database: process.env.POSTGRES_DB || 'norsain',
  user: process.env.POSTGRES_USER || 'postgres',
  password: process.env.POSTGRES_PASSWORD,
};

const WS_PORT = parseInt(process.env.WS_PORT || '8080');
const WS_HOST = process.env.WS_HOST || '0.0.0.0';
const NOTIFICATION_CHANNELS = (process.env.NOTIFICATION_CHANNELS || 'db_changes').split(',').map(ch => ch.trim());

// PostgreSQL client for LISTEN
let pgClient = null;

// WebSocket server
const wss = new WebSocketServer({ 
  host: WS_HOST,
  port: WS_PORT 
});

// Store active connections with their subscribed channels
const connections = new Map();

async function connectToPostgres() {
  try {
    pgClient = new Client(POSTGRES_CONFIG);
    await pgClient.connect();
    console.log('✓ Connected to PostgreSQL');

    // Set up error handler
    pgClient.on('error', (err) => {
      console.error('PostgreSQL client error:', err);
      handlePostgresDisconnect();
    });

    // Set up notification handler
    pgClient.on('notification', (msg) => {
      console.log(`📨 Notification from channel "${msg.channel}":`, msg.payload);
      broadcastToSubscribers(msg.channel, msg.payload);
    });

    // Listen to all configured channels
    for (const channel of NOTIFICATION_CHANNELS) {
      await pgClient.query(`LISTEN ${channel}`);
      console.log(`👂 Listening to channel: ${channel}`);
    }

    return true;
  } catch (err) {
    console.error('Failed to connect to PostgreSQL:', err);
    return false;
  }
}

async function handlePostgresDisconnect() {
  console.log('Attempting to reconnect to PostgreSQL...');
  pgClient = null;
  
  // Retry connection with exponential backoff
  let retryDelay = 1000;
  while (!pgClient || pgClient.ended) {
    await new Promise(resolve => setTimeout(resolve, retryDelay));
    const connected = await connectToPostgres();
    if (connected) break;
    retryDelay = Math.min(retryDelay * 2, 30000); // Max 30 seconds
  }
}

function broadcastToSubscribers(channel, payload) {
  let count = 0;
  connections.forEach((clientData, ws) => {
    if (ws.readyState === ws.OPEN && clientData.channels.has(channel)) {
      try {
        const message = JSON.stringify({
          type: 'notification',
          channel: channel,
          payload: payload,
          timestamp: new Date().toISOString()
        });
        ws.send(message);
        count++;
      } catch (err) {
        console.error('Error sending message to client:', err);
      }
    }
  });
  console.log(`📤 Broadcast to ${count} client(s) on channel "${channel}"`);
}

// Handle WebSocket connections
wss.on('connection', (ws) => {
  const clientId = Math.random().toString(36).substring(7);
  console.log(`🔌 Client connected: ${clientId}`);

  // Initialize client data
  connections.set(ws, {
    id: clientId,
    channels: new Set(),
    connectedAt: new Date()
  });

  // Send welcome message
  ws.send(JSON.stringify({
    type: 'connected',
    clientId: clientId,
    availableChannels: NOTIFICATION_CHANNELS,
    message: 'Connected to WebSocket server'
  }));

  // Handle incoming messages
  ws.on('message', (data) => {
    try {
      const message = JSON.parse(data.toString());
      handleClientMessage(ws, message);
    } catch (err) {
      console.error('Error parsing client message:', err);
      ws.send(JSON.stringify({
        type: 'error',
        message: 'Invalid JSON message'
      }));
    }
  });

  // Handle client disconnect
  ws.on('close', () => {
    const clientData = connections.get(ws);
    console.log(`👋 Client disconnected: ${clientData?.id}`);
    connections.delete(ws);
  });

  // Handle errors
  ws.on('error', (err) => {
    console.error('WebSocket error:', err);
  });
});

function handleClientMessage(ws, message) {
  const clientData = connections.get(ws);
  
  switch (message.type) {
    case 'subscribe':
      if (message.channel && NOTIFICATION_CHANNELS.includes(message.channel)) {
        clientData.channels.add(message.channel);
        console.log(`✓ Client ${clientData.id} subscribed to: ${message.channel}`);
        ws.send(JSON.stringify({
          type: 'subscribed',
          channel: message.channel,
          message: `Subscribed to channel: ${message.channel}`
        }));
      } else {
        ws.send(JSON.stringify({
          type: 'error',
          message: `Invalid channel: ${message.channel}. Available: ${NOTIFICATION_CHANNELS.join(', ')}`
        }));
      }
      break;

    case 'unsubscribe':
      if (message.channel) {
        clientData.channels.delete(message.channel);
        console.log(`✓ Client ${clientData.id} unsubscribed from: ${message.channel}`);
        ws.send(JSON.stringify({
          type: 'unsubscribed',
          channel: message.channel,
          message: `Unsubscribed from channel: ${message.channel}`
        }));
      }
      break;

    case 'ping':
      ws.send(JSON.stringify({
        type: 'pong',
        timestamp: new Date().toISOString()
      }));
      break;

    case 'list_channels':
      ws.send(JSON.stringify({
        type: 'channels',
        availableChannels: NOTIFICATION_CHANNELS,
        subscribedChannels: Array.from(clientData.channels)
      }));
      break;

    default:
      ws.send(JSON.stringify({
        type: 'error',
        message: `Unknown message type: ${message.type}`
      }));
  }
}

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down gracefully...');
  
  // Close all WebSocket connections
  wss.clients.forEach((client) => {
    client.close(1000, 'Server shutting down');
  });
  
  // Close WebSocket server
  wss.close(() => {
    console.log('✓ WebSocket server closed');
  });

  // Close PostgreSQL connection
  if (pgClient) {
    await pgClient.end();
    console.log('✓ PostgreSQL connection closed');
  }

  process.exit(0);
});

// Start the server
async function start() {
  console.log('🚀 Starting WebSocket server...');
  console.log(`Configuration:
  - PostgreSQL: ${POSTGRES_CONFIG.host}:${POSTGRES_CONFIG.port}/${POSTGRES_CONFIG.database}
  - WebSocket: ${WS_HOST}:${WS_PORT}
  - Channels: ${NOTIFICATION_CHANNELS.join(', ')}
  `);

  const connected = await connectToPostgres();
  
  if (!connected) {
    console.error('❌ Failed to connect to PostgreSQL. Exiting...');
    process.exit(1);
  }

  console.log(`✓ WebSocket server listening on ${WS_HOST}:${WS_PORT}`);
  console.log('Ready to accept connections! 🎉\n');
}

start().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});
