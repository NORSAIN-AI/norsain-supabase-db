# WebSocket API Documentation

## Connection

Connect to the WebSocket server at:
```
ws://your-host:8080
```

Or with SSL/TLS:
```
wss://your-host:8080
```

## Message Format

All messages are JSON-formatted strings.

## Client → Server Messages

### Subscribe to Channel

Subscribe to receive notifications from a specific channel.

**Request:**
```json
{
  "type": "subscribe",
  "channel": "db_changes"
}
```

**Response:**
```json
{
  "type": "subscribed",
  "channel": "db_changes",
  "message": "Subscribed to channel: db_changes"
}
```

**Error Response:**
```json
{
  "type": "error",
  "message": "Invalid channel: invalid_channel. Available: db_changes, table_updates"
}
```

---

### Unsubscribe from Channel

Stop receiving notifications from a specific channel.

**Request:**
```json
{
  "type": "unsubscribe",
  "channel": "db_changes"
}
```

**Response:**
```json
{
  "type": "unsubscribed",
  "channel": "db_changes",
  "message": "Unsubscribed from channel: db_changes"
}
```

---

### List Channels

Get a list of available channels and your subscriptions.

**Request:**
```json
{
  "type": "list_channels"
}
```

**Response:**
```json
{
  "type": "channels",
  "availableChannels": ["db_changes", "table_updates"],
  "subscribedChannels": ["db_changes"]
}
```

---

### Ping

Test the connection to the server.

**Request:**
```json
{
  "type": "ping"
}
```

**Response:**
```json
{
  "type": "pong",
  "timestamp": "2025-01-15T10:30:45.123Z"
}
```

---

## Server → Client Messages

### Connected

Sent immediately after a successful connection.

```json
{
  "type": "connected",
  "clientId": "abc123",
  "availableChannels": ["db_changes", "table_updates"],
  "message": "Connected to WebSocket server"
}
```

---

### Notification

Sent when a database change occurs on a subscribed channel.

```json
{
  "type": "notification",
  "channel": "db_changes",
  "payload": {
    "table": "users",
    "operation": "INSERT",
    "new_data": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "created_at": "2025-01-15T10:30:45.123Z"
    }
  },
  "timestamp": "2025-01-15T10:30:45.123Z"
}
```

**Payload structure depends on your trigger configuration:**

- **INSERT**: Contains `new_data`
- **UPDATE**: Contains `old_data` and `new_data`
- **DELETE**: Contains `old_data`

---

### Error

Sent when an error occurs.

```json
{
  "type": "error",
  "message": "Error description"
}
```

Common errors:
- Invalid JSON message
- Unknown message type
- Invalid channel name

---

## Examples

### JavaScript/Browser

```javascript
const ws = new WebSocket('ws://localhost:8080');

ws.onopen = () => {
  console.log('Connected');
  
  // Subscribe to a channel
  ws.send(JSON.stringify({
    type: 'subscribe',
    channel: 'db_changes'
  }));
};

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  
  switch(message.type) {
    case 'connected':
      console.log('Connection established:', message.clientId);
      break;
      
    case 'notification':
      console.log('Database change:', message.payload);
      // Handle the change...
      break;
      
    case 'error':
      console.error('Error:', message.message);
      break;
  }
};

ws.onerror = (error) => {
  console.error('WebSocket error:', error);
};

ws.onclose = () => {
  console.log('Disconnected');
};
```

---

### Node.js

```javascript
import { WebSocket } from 'ws';

const ws = new WebSocket('ws://localhost:8080');

ws.on('open', () => {
  console.log('Connected');
  
  ws.send(JSON.stringify({
    type: 'subscribe',
    channel: 'db_changes'
  }));
});

ws.on('message', (data) => {
  const message = JSON.parse(data.toString());
  
  if (message.type === 'notification') {
    console.log('Database change:', message.payload);
  }
});

ws.on('error', console.error);
ws.on('close', () => console.log('Disconnected'));
```

---

### Python

```python
import websocket
import json

def on_message(ws, message):
    data = json.loads(message)
    
    if data['type'] == 'notification':
        print('Database change:', data['payload'])

def on_open(ws):
    print('Connected')
    ws.send(json.dumps({
        'type': 'subscribe',
        'channel': 'db_changes'
    }))

def on_error(ws, error):
    print('Error:', error)

def on_close(ws, close_status_code, close_msg):
    print('Disconnected')

ws = websocket.WebSocketApp(
    'ws://localhost:8080',
    on_message=on_message,
    on_open=on_open,
    on_error=on_error,
    on_close=on_close
)

ws.run_forever()
```

---

### cURL (Testing)

You can test the connection with `websocat` or similar tools:

```bash
# Install websocat
brew install websocat  # macOS
# or
apt install websocat   # Linux

# Connect and send messages
echo '{"type":"subscribe","channel":"db_changes"}' | websocat ws://localhost:8080
```

---

## Best Practices

1. **Always handle errors**: Implement error handlers for connection failures and message errors.

2. **Reconnection logic**: Implement automatic reconnection with exponential backoff:
   ```javascript
   let reconnectDelay = 1000;
   
   function connect() {
     const ws = new WebSocket('ws://localhost:8080');
     
     ws.onclose = () => {
       setTimeout(() => {
         reconnectDelay = Math.min(reconnectDelay * 2, 30000);
         connect();
       }, reconnectDelay);
     };
     
     ws.onopen = () => {
       reconnectDelay = 1000; // Reset delay on successful connection
     };
   }
   ```

3. **Validate messages**: Always validate incoming messages before processing.

4. **Subscribe after connection**: Wait for the `connected` message before subscribing to channels.

5. **Heartbeat/Ping**: Send periodic pings to keep the connection alive:
   ```javascript
   setInterval(() => {
     if (ws.readyState === WebSocket.OPEN) {
       ws.send(JSON.stringify({ type: 'ping' }));
     }
   }, 30000); // Every 30 seconds
   ```

6. **Clean up**: Always close connections when they're no longer needed:
   ```javascript
   window.addEventListener('beforeunload', () => {
     ws.close();
   });
   ```

---

## Rate Limiting and Throttling

Currently, there is no built-in rate limiting. For production use, consider:

- Implementing rate limiting on the server
- Throttling notifications on high-frequency changes
- Using message batching for bulk operations

---

## Security Considerations

⚠️ **Important**: This server does not include authentication by default.

For production deployments:

1. **Add authentication**: Implement token-based authentication (JWT)
2. **Use TLS**: Always use `wss://` in production
3. **Validate origins**: Implement CORS and origin validation
4. **Sanitize data**: Validate and sanitize all database notifications
5. **Network security**: Use firewalls and network segmentation
6. **Monitor**: Implement logging and monitoring for suspicious activity
