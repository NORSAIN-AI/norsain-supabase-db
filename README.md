# norsain-supabase-db
Supabase migrasjoner, seeds og RLS-policyer for NORSAIN MAS

## MCP Server for MAS Agents

Dette prosjektet inkluderer en Model Context Protocol (MCP) server som lar MAS-agenter få sikker tilgang til Supabase-databasen.

### Funksjoner

MCP-serveren tilbyr følgende verktøy for agenter:

- **query_database**: Utfør SQL-spørringer (kun SELECT for sikkerhet)
- **list_tables**: List alle tabeller i databasen
- **get_table_data**: Hent data fra en spesifikk tabell
- **insert_data**: Sett inn data i en tabell
- **update_data**: Oppdater data i en tabell
- **delete_data**: Slett data fra en tabell

### Installasjon

1. Klon repositoryet:
```bash
git clone https://github.com/NORSAIN-AI/norsain-supabase-db.git
cd norsain-supabase-db
```

2. Installer avhengigheter:
```bash
npm install
```

3. Konfigurer miljøvariabler:
```bash
cp .env.example .env
# Rediger .env med dine Supabase-detaljer
```

4. Bygg prosjektet:
```bash
npm run build
```

### Bruk

#### Med Claude Desktop

Legg til følgende i Claude Desktop konfigurasjon (`~/Library/Application Support/Claude/claude_desktop_config.json` på macOS eller `%APPDATA%\Claude\claude_desktop_config.json` på Windows):

```json
{
  "mcpServers": {
    "norsain-supabase": {
      "command": "node",
      "args": ["/path/to/norsain-supabase-db/dist/index.js"],
      "env": {
        "SUPABASE_URL": "https://your-project.supabase.co",
        "SUPABASE_KEY": "your-supabase-key"
      }
    }
  }
}
```

#### Med andre MCP-klienter

MCP-serveren bruker stdio-transport og kan brukes med hvilken som helst MCP-klient som støtter stdio.

```bash
SUPABASE_URL=https://your-project.supabase.co \
SUPABASE_KEY=your-key \
node dist/index.js
```

### Utvikling

```bash
# Bygg prosjektet
npm run build

# Bygg med watch mode
npm run watch

# Kjør serveren
npm start
```

### Ressurser

Serveren tilbyr følgende ressurser:

- `supabase://database/schema` - Komplett skjemainformasjon for alle tabeller
- `supabase://database/info` - Generell informasjon om databasetilkoblingen

### Sikkerhet

- SQL-spørringer er begrenset til SELECT-statements for sikkerhet
- Serveren krever gyldig SUPABASE_URL og SUPABASE_KEY
- Row Level Security (RLS) policyer i Supabase gjelder fortsatt

### Lisens

MIT
