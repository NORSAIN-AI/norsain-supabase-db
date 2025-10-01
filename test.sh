#!/bin/bash

# Test script for NORSAIN Supabase MCP Server
# This script verifies the server can start with proper configuration

echo "Testing NORSAIN Supabase MCP Server..."
echo ""

# Check if dist directory exists
if [ ! -d "dist" ]; then
    echo "❌ Error: dist directory not found. Run 'npm run build' first."
    exit 1
fi

# Check if index.js exists
if [ ! -f "dist/index.js" ]; then
    echo "❌ Error: dist/index.js not found. Run 'npm run build' first."
    exit 1
fi

echo "✅ Build files found"

# Test without environment variables (should fail gracefully)
echo ""
echo "Testing without environment variables (should fail)..."
output=$(node dist/index.js 2>&1)
if echo "$output" | grep -q "SUPABASE_URL and SUPABASE_KEY environment variables are required"; then
    echo "✅ Server correctly validates environment variables"
else
    echo "❌ Unexpected output: $output"
    exit 1
fi

echo ""
echo "✅ All basic tests passed!"
echo ""
echo "To use the server, set SUPABASE_URL and SUPABASE_KEY environment variables:"
echo "  export SUPABASE_URL=https://your-project.supabase.co"
echo "  export SUPABASE_KEY=your-key"
echo "  node dist/index.js"
