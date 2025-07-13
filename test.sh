#!/bin/bash

# Wrapper script to run the complete test workflow

echo "🧪 Running PostgreSQL MCP Server Tests"
echo "======================================="
echo ""

# Run the complete test workflow
./test/scripts/test-complete.sh
