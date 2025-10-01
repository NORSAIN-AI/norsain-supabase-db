# norsain-supabase-db
Supabase migrasjoner, seeds og RLS-policyer for NORSAIN MAS

## WebSocket Server for Real-time Database Changes

Dette repositoriet inneholder en WebSocket-server for å lytte på PostgreSQL-endringer i sanntid ved hjelp av PostgreSQL LISTEN/NOTIFY-funksjonalitet.

### Funksjoner

- 🔄 **Sanntids database-endringer**: Mottar umiddelbare varsler når data endres i PostgreSQL
- 🔌 **WebSocket-basert**: Enkel integrasjon med webapplikasjoner og klienter
- 📢 **Flere kanaler**: Støtte for flere notifikasjonskanaler samtidig
- 🔒 **Robust**: Automatisk reconnect ved feil og god feilhåndtering
- ⚡ **Lett**: Minimal overhead og rask ytelse

### Installasjon

1. **Klon repositoriet**:
```bash
git clone https://github.com/NORSAIN-AI/norsain-supabase-db.git
cd norsain-supabase-db
```

2. **Installer avhengigheter**:
```bash
npm install
```

3. **Konfigurer miljøvariabler**:
```bash
cp .env.example .env
# Rediger .env med dine database-detaljer
```

4. **Sett opp PostgreSQL-triggere**:
```bash
# Kjør SQL-skriptet i databasen din
psql -U postgres -d norsain -f examples/setup_triggers.sql
```

### Bruk

#### Start serveren

```bash
# Produksjon
npm start

# Utvikling (med auto-restart)
npm run dev
```

Serveren vil starte på `ws://localhost:8080` (eller den konfigurerte porten).

#### Koble til fra en klient

**JavaScript/Node.js:**
```javascript
const ws = new WebSocket('ws://localhost:8080');

ws.on('open', () => {
  console.log('Tilkoblet WebSocket-server');
  
  // Abonner på en kanal
  ws.send(JSON.stringify({
    type: 'subscribe',
    channel: 'db_changes'
  }));
});

ws.on('message', (data) => {
  const message = JSON.parse(data);
  
  if (message.type === 'notification') {
    console.log('Database-endring:', message.payload);
  }
});
```

**Python:**
```python
import websocket
import json

def on_message(ws, message):
    data = json.loads(message)
    if data['type'] == 'notification':
        print('Database-endring:', data['payload'])

def on_open(ws):
    ws.send(json.dumps({
        'type': 'subscribe',
        'channel': 'db_changes'
    }))

ws = websocket.WebSocketApp('ws://localhost:8080',
                            on_message=on_message,
                            on_open=on_open)
ws.run_forever()
```

#### Meldingstyper

**Klient til server:**
- `subscribe`: Abonner på en kanal
- `unsubscribe`: Avslutt abonnement på en kanal
- `list_channels`: List tilgjengelige kanaler
- `ping`: Ping serveren

**Server til klient:**
- `connected`: Bekreftelse på tilkobling
- `notification`: Database-endring mottatt
- `subscribed`: Bekreftelse på abonnement
- `unsubscribed`: Bekreftelse på avsluttet abonnement
- `channels`: Liste over kanaler
- `pong`: Svar på ping
- `error`: Feilmelding

### Testing

Bruk den inkluderte HTML-testklienten for å teste serveren:

1. Start serveren: `npm start`
2. Åpne `examples/test-client.html` i en nettleser
3. Klikk "Connect" for å koble til serveren
4. Abonner på kanaler og gjør database-endringer for å se notifikasjoner

### PostgreSQL LISTEN/NOTIFY

Serveren bruker PostgreSQL sin innebygde LISTEN/NOTIFY-funksjonalitet. For å sende notifikasjoner fra databasen, må du sette opp triggere:

```sql
-- Eksempel på trigger-funksjon
CREATE OR REPLACE FUNCTION notify_db_changes()
RETURNS trigger AS $$
DECLARE
  payload JSON;
BEGIN
  payload = json_build_object(
    'table', TG_TABLE_NAME,
    'operation', TG_OP,
    'data', CASE 
      WHEN TG_OP = 'DELETE' THEN row_to_json(OLD)
      ELSE row_to_json(NEW)
    END
  );
  
  PERFORM pg_notify('db_changes', payload::text);
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Opprett trigger på en tabell
CREATE TRIGGER my_table_trigger
  AFTER INSERT OR UPDATE OR DELETE ON my_table
  FOR EACH ROW
  EXECUTE FUNCTION notify_db_changes();
```

Se `examples/setup_triggers.sql` for flere eksempler.

### Konfigurasjon

Miljøvariabler i `.env`:

- `POSTGRES_HOST`: PostgreSQL server host (standard: localhost)
- `POSTGRES_PORT`: PostgreSQL server port (standard: 5432)
- `POSTGRES_DB`: Database-navn
- `POSTGRES_USER`: Database-bruker
- `POSTGRES_PASSWORD`: Database-passord
- `WS_PORT`: WebSocket server port (standard: 8080)
- `WS_HOST`: WebSocket server host (standard: 0.0.0.0)
- `NOTIFICATION_CHANNELS`: Kommaseparert liste over kanaler å lytte på

### Sikkerhet

⚠️ **Viktig**: Denne serveren er beregnet for intern bruk og inkluderer ikke autentisering. For produksjonsmiljøer, bør du:

- Implementere autentisering (JWT, API-nøkler, etc.)
- Bruke SSL/TLS (wss://)
- Begrense tilgang med nettverksregler
- Validere og sanitere data fra databasen
- Implementere rate limiting

### Feilsøking

**Serveren kan ikke koble til PostgreSQL:**
- Sjekk at PostgreSQL kjører
- Verifiser at credentials i `.env` er korrekte
- Sjekk at brukeren har rettigheter til å bruke LISTEN

**Ingen notifikasjoner mottas:**
- Sjekk at triggerne er riktig konfigurert i databasen
- Verifiser at kanal-navnet i trigger matcher `NOTIFICATION_CHANNELS`
- Test med manuell NOTIFY: `SELECT pg_notify('db_changes', '{"test": "data"}');`

**WebSocket-tilkoblingsproblemer:**
- Sjekk at porten ikke er blokkert av brannmur
- Verifiser at WebSocket-URL er korrekt
- Se på server-logger for feilmeldinger

### Lisens

MIT License - se [LICENSE](LICENSE) for detaljer.
