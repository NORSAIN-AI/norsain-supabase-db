# MCP Tools and Resources Documentation

## Tools

### 1. query_database

Execute SQL queries on the Supabase database (SELECT only for safety).

**Input Schema:**
```json
{
  "query": "SELECT * FROM table_name WHERE condition"
}
```

**Example:**
```json
{
  "query": "SELECT id, name, created_at FROM users LIMIT 10"
}
```

**Response:** JSON array of query results

---

### 2. list_tables

List all tables in the database with their schema information.

**Input Schema:** None required

**Response:** JSON array with table names and schemas

---

### 3. get_table_data

Retrieve data from a specific table.

**Input Schema:**
```json
{
  "table": "table_name",
  "limit": 100  // optional, default: 100
}
```

**Example:**
```json
{
  "table": "users",
  "limit": 50
}
```

**Response:** JSON array of table rows

---

### 4. insert_data

Insert new data into a table.

**Input Schema:**
```json
{
  "table": "table_name",
  "data": {
    "column1": "value1",
    "column2": "value2"
  }
}
```

Or for multiple rows:
```json
{
  "table": "table_name",
  "data": [
    {"column1": "value1", "column2": "value2"},
    {"column1": "value3", "column2": "value4"}
  ]
}
```

**Example:**
```json
{
  "table": "users",
  "data": {
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

**Response:** Confirmation message with inserted data

---

### 5. update_data

Update existing data in a table.

**Input Schema:**
```json
{
  "table": "table_name",
  "data": {
    "column1": "new_value"
  },
  "match": {
    "id": 123
  }
}
```

**Example:**
```json
{
  "table": "users",
  "data": {
    "status": "active"
  },
  "match": {
    "id": 42
  }
}
```

**Response:** Confirmation message with updated data

---

### 6. delete_data

Delete data from a table.

**Input Schema:**
```json
{
  "table": "table_name",
  "match": {
    "id": 123
  }
}
```

**Example:**
```json
{
  "table": "users",
  "match": {
    "status": "inactive"
  }
}
```

**Response:** Confirmation message with number of deleted rows

---

## Resources

### 1. supabase://database/schema

Complete schema information for all tables in the database.

**URI:** `supabase://database/schema`

**MIME Type:** `application/json`

**Content:** JSON array with columns information:
- `table_name`: Name of the table
- `column_name`: Name of the column
- `data_type`: PostgreSQL data type
- `is_nullable`: Whether the column accepts NULL values

---

### 2. supabase://database/info

General information about the Supabase database connection.

**URI:** `supabase://database/info`

**MIME Type:** `application/json`

**Content:** JSON object with:
- `url`: Supabase project URL
- `connected`: Connection status
- `timestamp`: Current timestamp

---

## Error Handling

All tools and resources return errors in a consistent format:

```json
{
  "content": [
    {
      "type": "text",
      "text": "Error: [error message]"
    }
  ],
  "isError": true
}
```

## Security Considerations

1. **SQL Injection Protection**: The `query_database` tool only accepts SELECT statements
2. **RLS Policies**: All Supabase Row Level Security policies are enforced
3. **Authentication**: Requires valid SUPABASE_URL and SUPABASE_KEY
4. **Data Access**: Limited by the permissions of the API key used

## Best Practices

1. **Use Specific Queries**: When using `query_database`, be specific to reduce data transfer
2. **Limit Results**: Always use `limit` parameter for large tables
3. **Batch Operations**: Use arrays with `insert_data` for multiple rows
4. **Test First**: Use `get_table_data` with low limits to understand table structure
5. **Monitor Usage**: Check database logs for query performance
