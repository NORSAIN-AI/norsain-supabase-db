#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { CallToolRequestSchema, ListToolsRequestSchema, ListResourcesRequestSchema, ReadResourceRequestSchema, } from "@modelcontextprotocol/sdk/types.js";
import { createClient } from "@supabase/supabase-js";
// Environment variables for Supabase connection
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_KEY;
if (!SUPABASE_URL || !SUPABASE_KEY) {
    console.error("Error: SUPABASE_URL and SUPABASE_KEY environment variables are required");
    process.exit(1);
}
// Initialize Supabase client
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);
// Create MCP server
const server = new Server({
    name: "norsain-supabase-mcp",
    version: "1.0.0",
}, {
    capabilities: {
        tools: {},
        resources: {},
    },
});
// Define available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
    return {
        tools: [
            {
                name: "query_database",
                description: "Execute a SQL query on the Supabase database. Returns the query results.",
                inputSchema: {
                    type: "object",
                    properties: {
                        query: {
                            type: "string",
                            description: "SQL query to execute (SELECT statements only for safety)",
                        },
                    },
                    required: ["query"],
                },
            },
            {
                name: "list_tables",
                description: "List all tables in the database with their schema information",
                inputSchema: {
                    type: "object",
                    properties: {},
                },
            },
            {
                name: "get_table_data",
                description: "Retrieve all data from a specific table",
                inputSchema: {
                    type: "object",
                    properties: {
                        table: {
                            type: "string",
                            description: "Name of the table to query",
                        },
                        limit: {
                            type: "number",
                            description: "Maximum number of rows to return (default: 100)",
                        },
                    },
                    required: ["table"],
                },
            },
            {
                name: "insert_data",
                description: "Insert data into a table",
                inputSchema: {
                    type: "object",
                    properties: {
                        table: {
                            type: "string",
                            description: "Name of the table to insert into",
                        },
                        data: {
                            type: "object",
                            description: "Data to insert (JSON object or array of objects)",
                        },
                    },
                    required: ["table", "data"],
                },
            },
            {
                name: "update_data",
                description: "Update data in a table",
                inputSchema: {
                    type: "object",
                    properties: {
                        table: {
                            type: "string",
                            description: "Name of the table to update",
                        },
                        data: {
                            type: "object",
                            description: "Data to update (JSON object)",
                        },
                        match: {
                            type: "object",
                            description: "Match conditions (JSON object)",
                        },
                    },
                    required: ["table", "data", "match"],
                },
            },
            {
                name: "delete_data",
                description: "Delete data from a table",
                inputSchema: {
                    type: "object",
                    properties: {
                        table: {
                            type: "string",
                            description: "Name of the table to delete from",
                        },
                        match: {
                            type: "object",
                            description: "Match conditions (JSON object)",
                        },
                    },
                    required: ["table", "match"],
                },
            },
        ],
    };
});
// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;
    try {
        switch (name) {
            case "query_database": {
                const { query } = args;
                // Safety check: only allow SELECT queries
                if (!query.trim().toUpperCase().startsWith("SELECT")) {
                    throw new Error("Only SELECT queries are allowed for safety reasons");
                }
                const { data, error } = await supabase.rpc("exec_sql", { query_text: query });
                if (error)
                    throw error;
                return {
                    content: [
                        {
                            type: "text",
                            text: JSON.stringify(data, null, 2),
                        },
                    ],
                };
            }
            case "list_tables": {
                const { data, error } = await supabase
                    .from("information_schema.tables")
                    .select("table_name, table_schema")
                    .eq("table_schema", "public");
                if (error)
                    throw error;
                return {
                    content: [
                        {
                            type: "text",
                            text: JSON.stringify(data, null, 2),
                        },
                    ],
                };
            }
            case "get_table_data": {
                const { table, limit = 100 } = args;
                const { data, error } = await supabase
                    .from(table)
                    .select("*")
                    .limit(limit);
                if (error)
                    throw error;
                return {
                    content: [
                        {
                            type: "text",
                            text: JSON.stringify(data, null, 2),
                        },
                    ],
                };
            }
            case "insert_data": {
                const { table, data } = args;
                const { data: result, error } = await supabase
                    .from(table)
                    .insert(data)
                    .select();
                if (error)
                    throw error;
                return {
                    content: [
                        {
                            type: "text",
                            text: `Successfully inserted ${Array.isArray(result) ? result.length : 1} row(s)\n${JSON.stringify(result, null, 2)}`,
                        },
                    ],
                };
            }
            case "update_data": {
                const { table, data, match } = args;
                const { data: result, error } = await supabase
                    .from(table)
                    .update(data)
                    .match(match)
                    .select();
                if (error)
                    throw error;
                return {
                    content: [
                        {
                            type: "text",
                            text: `Successfully updated ${Array.isArray(result) ? result.length : 0} row(s)\n${JSON.stringify(result, null, 2)}`,
                        },
                    ],
                };
            }
            case "delete_data": {
                const { table, match } = args;
                const { data: result, error } = await supabase
                    .from(table)
                    .delete()
                    .match(match)
                    .select();
                if (error)
                    throw error;
                return {
                    content: [
                        {
                            type: "text",
                            text: `Successfully deleted ${Array.isArray(result) ? result.length : 0} row(s)\n${JSON.stringify(result, null, 2)}`,
                        },
                    ],
                };
            }
            default:
                throw new Error(`Unknown tool: ${name}`);
        }
    }
    catch (error) {
        return {
            content: [
                {
                    type: "text",
                    text: `Error: ${error instanceof Error ? error.message : String(error)}`,
                },
            ],
            isError: true,
        };
    }
});
// Define available resources
server.setRequestHandler(ListResourcesRequestSchema, async () => {
    return {
        resources: [
            {
                uri: "supabase://database/schema",
                name: "Database Schema",
                description: "Complete schema information for all tables in the database",
                mimeType: "application/json",
            },
            {
                uri: "supabase://database/info",
                name: "Database Information",
                description: "General information about the Supabase database connection",
                mimeType: "application/json",
            },
        ],
    };
});
// Handle resource reads
server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
    const { uri } = request.params;
    try {
        if (uri === "supabase://database/schema") {
            const { data, error } = await supabase
                .from("information_schema.columns")
                .select("table_name, column_name, data_type, is_nullable")
                .eq("table_schema", "public")
                .order("table_name")
                .order("ordinal_position");
            if (error)
                throw error;
            return {
                contents: [
                    {
                        uri,
                        mimeType: "application/json",
                        text: JSON.stringify(data, null, 2),
                    },
                ],
            };
        }
        else if (uri === "supabase://database/info") {
            return {
                contents: [
                    {
                        uri,
                        mimeType: "application/json",
                        text: JSON.stringify({
                            url: SUPABASE_URL,
                            connected: true,
                            timestamp: new Date().toISOString(),
                        }, null, 2),
                    },
                ],
            };
        }
        else {
            throw new Error(`Unknown resource: ${uri}`);
        }
    }
    catch (error) {
        throw new Error(`Error reading resource: ${error instanceof Error ? error.message : String(error)}`);
    }
});
// Start the server
async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error("NORSAIN Supabase MCP Server running on stdio");
}
main().catch((error) => {
    console.error("Fatal error:", error);
    process.exit(1);
});
//# sourceMappingURL=index.js.map