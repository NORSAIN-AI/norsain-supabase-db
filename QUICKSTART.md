# Quick Start Guide

## Setup Instructions

### 1. Install Dependencies
```bash
npm install
```

### 2. Build the Project
```bash
npm run build
```

### 3. Configure Environment Variables

Create a `.env` file or set environment variables:
```bash
export SUPABASE_URL=https://your-project.supabase.co
export SUPABASE_KEY=your-supabase-key
```

### 4. Test the Server
```bash
./test.sh
```

## Usage with Claude Desktop

### macOS
Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "norsain-supabase": {
      "command": "node",
      "args": ["/absolute/path/to/norsain-supabase-db/dist/index.js"],
      "env": {
        "SUPABASE_URL": "https://your-project.supabase.co",
        "SUPABASE_KEY": "your-supabase-key"
      }
    }
  }
}
```

### Windows
Edit `%APPDATA%\Claude\claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "norsain-supabase": {
      "command": "node",
      "args": ["C:\\path\\to\\norsain-supabase-db\\dist\\index.js"],
      "env": {
        "SUPABASE_URL": "https://your-project.supabase.co",
        "SUPABASE_KEY": "your-supabase-key"
      }
    }
  }
}
```

### Linux
Edit `~/.config/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "norsain-supabase": {
      "command": "node",
      "args": ["/absolute/path/to/norsain-supabase-db/dist/index.js"],
      "env": {
        "SUPABASE_URL": "https://your-project.supabase.co",
        "SUPABASE_KEY": "your-supabase-key"
      }
    }
  }
}
```

## Available Tools

Once configured, MAS agents will have access to these tools:

- `query_database` - Execute SQL SELECT queries
- `list_tables` - List all database tables
- `get_table_data` - Retrieve data from a table
- `insert_data` - Insert new records
- `update_data` - Update existing records
- `delete_data` - Delete records

## Available Resources

- `supabase://database/schema` - Complete database schema
- `supabase://database/info` - Connection information

## Security Notes

- Only SELECT queries are allowed via `query_database` for safety
- All Supabase Row Level Security (RLS) policies remain in effect
- Use service role key only if you need full database access
- Use anon key for limited access with RLS policies

## Troubleshooting

### Server won't start
- Check that environment variables are set correctly
- Verify Supabase URL and key are valid
- Run `./test.sh` to diagnose issues

### Can't connect to database
- Verify your Supabase project is active
- Check network connectivity
- Ensure the API key has appropriate permissions

### Claude Desktop doesn't see the server
- Restart Claude Desktop after config changes
- Check the config file path is correct
- Verify the absolute path to index.js is correct
- Check Claude Desktop logs for errors
