import { WebSocket } from 'ws';

// Simple test client for the WebSocket server
console.log('🧪 Testing WebSocket Server...\n');

const WS_URL = 'ws://localhost:8080';
let testsPassed = 0;
let testsFailed = 0;

function test(name, fn) {
  return new Promise((resolve) => {
    console.log(`▶️  ${name}`);
    fn()
      .then(() => {
        testsPassed++;
        console.log(`✅ PASSED: ${name}\n`);
        resolve();
      })
      .catch((err) => {
        testsFailed++;
        console.error(`❌ FAILED: ${name}`);
        console.error(`   Error: ${err.message}\n`);
        resolve();
      });
  });
}

async function testConnection() {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(WS_URL);
    const timeout = setTimeout(() => {
      ws.close();
      reject(new Error('Connection timeout'));
    }, 5000);

    ws.on('open', () => {
      clearTimeout(timeout);
      ws.close();
      resolve();
    });

    ws.on('error', (err) => {
      clearTimeout(timeout);
      reject(err);
    });
  });
}

async function testWelcomeMessage() {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(WS_URL);
    const timeout = setTimeout(() => {
      ws.close();
      reject(new Error('Timeout waiting for welcome message'));
    }, 5000);

    ws.on('message', (data) => {
      try {
        const message = JSON.parse(data.toString());
        if (message.type === 'connected' && message.clientId) {
          clearTimeout(timeout);
          ws.close();
          resolve();
        }
      } catch (err) {
        clearTimeout(timeout);
        ws.close();
        reject(err);
      }
    });

    ws.on('error', (err) => {
      clearTimeout(timeout);
      reject(err);
    });
  });
}

async function testSubscribe() {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(WS_URL);
    const timeout = setTimeout(() => {
      ws.close();
      reject(new Error('Timeout waiting for subscription confirmation'));
    }, 5000);
    let welcomeReceived = false;

    ws.on('message', (data) => {
      try {
        const message = JSON.parse(data.toString());
        
        if (message.type === 'connected') {
          welcomeReceived = true;
          // Send subscribe message
          ws.send(JSON.stringify({
            type: 'subscribe',
            channel: 'db_changes'
          }));
        } else if (message.type === 'subscribed' && welcomeReceived) {
          clearTimeout(timeout);
          ws.close();
          resolve();
        }
      } catch (err) {
        clearTimeout(timeout);
        ws.close();
        reject(err);
      }
    });

    ws.on('error', (err) => {
      clearTimeout(timeout);
      reject(err);
    });
  });
}

async function testUnsubscribe() {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(WS_URL);
    const timeout = setTimeout(() => {
      ws.close();
      reject(new Error('Timeout waiting for unsubscription confirmation'));
    }, 5000);
    let welcomeReceived = false;
    let subscribed = false;

    ws.on('message', (data) => {
      try {
        const message = JSON.parse(data.toString());
        
        if (message.type === 'connected') {
          welcomeReceived = true;
          ws.send(JSON.stringify({
            type: 'subscribe',
            channel: 'db_changes'
          }));
        } else if (message.type === 'subscribed' && !subscribed) {
          subscribed = true;
          ws.send(JSON.stringify({
            type: 'unsubscribe',
            channel: 'db_changes'
          }));
        } else if (message.type === 'unsubscribed' && subscribed) {
          clearTimeout(timeout);
          ws.close();
          resolve();
        }
      } catch (err) {
        clearTimeout(timeout);
        ws.close();
        reject(err);
      }
    });

    ws.on('error', (err) => {
      clearTimeout(timeout);
      reject(err);
    });
  });
}

async function testPing() {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(WS_URL);
    const timeout = setTimeout(() => {
      ws.close();
      reject(new Error('Timeout waiting for pong'));
    }, 5000);
    let welcomeReceived = false;

    ws.on('message', (data) => {
      try {
        const message = JSON.parse(data.toString());
        
        if (message.type === 'connected') {
          welcomeReceived = true;
          ws.send(JSON.stringify({ type: 'ping' }));
        } else if (message.type === 'pong' && welcomeReceived) {
          clearTimeout(timeout);
          ws.close();
          resolve();
        }
      } catch (err) {
        clearTimeout(timeout);
        ws.close();
        reject(err);
      }
    });

    ws.on('error', (err) => {
      clearTimeout(timeout);
      reject(err);
    });
  });
}

async function testListChannels() {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(WS_URL);
    const timeout = setTimeout(() => {
      ws.close();
      reject(new Error('Timeout waiting for channels list'));
    }, 5000);
    let welcomeReceived = false;

    ws.on('message', (data) => {
      try {
        const message = JSON.parse(data.toString());
        
        if (message.type === 'connected') {
          welcomeReceived = true;
          ws.send(JSON.stringify({ type: 'list_channels' }));
        } else if (message.type === 'channels' && welcomeReceived) {
          if (Array.isArray(message.availableChannels)) {
            clearTimeout(timeout);
            ws.close();
            resolve();
          } else {
            throw new Error('Invalid channels response');
          }
        }
      } catch (err) {
        clearTimeout(timeout);
        ws.close();
        reject(err);
      }
    });

    ws.on('error', (err) => {
      clearTimeout(timeout);
      reject(err);
    });
  });
}

async function testInvalidChannel() {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(WS_URL);
    const timeout = setTimeout(() => {
      ws.close();
      reject(new Error('Timeout waiting for error message'));
    }, 5000);
    let welcomeReceived = false;

    ws.on('message', (data) => {
      try {
        const message = JSON.parse(data.toString());
        
        if (message.type === 'connected') {
          welcomeReceived = true;
          ws.send(JSON.stringify({
            type: 'subscribe',
            channel: 'invalid_channel_name'
          }));
        } else if (message.type === 'error' && welcomeReceived) {
          clearTimeout(timeout);
          ws.close();
          resolve();
        }
      } catch (err) {
        clearTimeout(timeout);
        ws.close();
        reject(err);
      }
    });

    ws.on('error', (err) => {
      clearTimeout(timeout);
      reject(err);
    });
  });
}

async function runTests() {
  console.log('Starting tests...\n');
  console.log(`Testing server at: ${WS_URL}\n`);
  console.log('⚠️  Make sure the server is running with: npm start\n');
  
  await test('Connect to WebSocket server', testConnection);
  await test('Receive welcome message', testWelcomeMessage);
  await test('Subscribe to channel', testSubscribe);
  await test('Unsubscribe from channel', testUnsubscribe);
  await test('Ping-pong', testPing);
  await test('List channels', testListChannels);
  await test('Handle invalid channel', testInvalidChannel);

  console.log('═'.repeat(50));
  console.log(`\n📊 Test Results:`);
  console.log(`   ✅ Passed: ${testsPassed}`);
  console.log(`   ❌ Failed: ${testsFailed}`);
  console.log(`   📈 Total:  ${testsPassed + testsFailed}\n`);
  
  if (testsFailed > 0) {
    console.log('❌ Some tests failed. Check the errors above.\n');
    process.exit(1);
  } else {
    console.log('✅ All tests passed! 🎉\n');
    process.exit(0);
  }
}

// Run tests
runTests().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
