# PostgreSQL MCP Server

A Model Context Protocol (MCP) server that provides read-only access to PostgreSQL databases.

## Features

- **Read-only operations**: Query data safely without risk of modifications
- **Schema inspection**: Explore database structure, tables, and columns
- **Query execution**: Run SELECT statements and view results
- **Connection management**: Secure connection handling with proper cleanup

## Installation

1. Clone this repository
2. Install dependencies:
   ```bash
   npm install
   ```

3. Build the project:
   ```bash
   npm run build
   ```

4. Configure your database connection (see Configuration section below)

## Configuration

Create a `.env` file in the root directory with your PostgreSQL connection details:

```env
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DATABASE=your_database
POSTGRES_USER=your_username
POSTGRES_PASSWORD=your_password
POSTGRES_SSL=false
```

## Usage

### Running the Server

```bash
npm start
```

### Available Tools

The MCP server provides the following tools:

1. **postgres_query** - Execute SELECT queries
2. **postgres_describe_table** - Get table structure and column information
3. **postgres_list_tables** - List all tables in the database
4. **postgres_list_schemas** - List all schemas in the database

### Example MCP Client Configuration

Add this to your MCP client configuration (e.g., `~/.config/claude-desktop/mcp.json`):

```json
{
  "servers": {
    "postgresql": {
      "command": "node",
      "args": ["path/to/mcp/server/start-server.cjs"],
      "type": "stdio"
    }
  }
}
```

This configuration automatically loads environment variables from your project's `.env` file, keeping sensitive credentials out of the MCP configuration.

## Security

This server operates in **read-only mode** only. It:
- Only allows SELECT statements
- Blocks INSERT, UPDATE, DELETE, DROP, CREATE, ALTER operations
- Uses parameterized queries to prevent SQL injection
- Validates all queries before execution

## Testing

### Quick Test
```bash
# Run complete test suite (includes security testing)
npm run test:complete
# or
./test.sh
```

### Test Environment
The project includes a comprehensive test environment with:
- PostgreSQL 15.13 in Docker
- Realistic e-commerce test data (74 records across 6 tables)
- Security validation tests
- Automated setup and cleanup

See [test/README.md](test/README.md) for detailed testing documentation.

## Development

```bash
# Development mode (rebuild and run)
npm run dev

# Build only (required after code changes)
npm run build

# Test database connection
npm run test-connection

# Test security features
npm run test-mcp-security
```

**Note**: You only need to run `npm run build` when you modify the TypeScript source code. For normal usage with different database credentials, just update your `.env` file.

## License

MIT
