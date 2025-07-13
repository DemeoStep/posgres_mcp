#!/usr/bin/env node

// CommonJS wrapper for the PostgreSQL MCP Server
const dotenv = require('dotenv');
const path = require('path');

// Load environment variables from .env file
dotenv.config({ path: path.join(__dirname, '.env') });

// Use dynamic import to load the ES module
async function startServer() {
  try {
    await import('./dist/index.js');
  } catch (error) {
    console.error('Failed to start PostgreSQL MCP Server:', error);
    process.exit(1);
  }
}

startServer();
