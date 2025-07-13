# PostgreSQL MCP Server Usage Examples

This document provides examples of how to use the PostgreSQL MCP server with various MCP clients.

## Quick Start

1. **Setup Environment Variables**
   ```bash
   cp .env.example .env
   # Edit .env with your PostgreSQL connection details
   ```

2. **Build the Server**
   ```bash
   npm run build
   ```

3. **Test Database Connection**
   ```bash
   npm run test-connection
   ```

## MCP Client Configuration

### Claude Desktop

Add this to your Claude Desktop configuration file (`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS):

```json
{
  "mcpServers": {
    "postgresql": {
      "command": "node",
      "args": ["/absolute/path/to/postgresql-mcp-server/dist/index.js"],
      "env": {
        "POSTGRES_HOST": "localhost",
        "POSTGRES_PORT": "5432", 
        "POSTGRES_DATABASE": "your_database",
        "POSTGRES_USER": "your_username",
        "POSTGRES_PASSWORD": "your_password",
        "POSTGRES_SSL": "false"
      }
    }
  }
}
```

### Other MCP Clients

For other MCP clients, use similar configuration with the command pointing to the built JavaScript file.

## Available Tools

### 1. postgres_query
Execute read-only SQL queries (SELECT statements only).

**Example Usage:**
```sql
SELECT * FROM users WHERE active = true ORDER BY created_at DESC LIMIT 10;
```

**Features:**
- Supports complex SELECT queries
- Allows JOINs, subqueries, CTEs (WITH clauses)
- Automatic result formatting
- Row count reporting

### 2. postgres_describe_table
Get detailed information about a table's structure.

**Parameters:**
- `table_name` (required): Name of the table
- `schema_name` (optional): Schema name (defaults to "public")

**Example:**
```
Table: users
Schema: public
```

**Returns:**
- Column names and data types
- Nullable constraints
- Default values
- Character limits
- Numeric precision/scale

### 3. postgres_list_tables
List all tables in the database.

**Parameters:**
- `schema_name` (optional): Filter by specific schema

**Returns:**
- Table schema
- Table name  
- Table type

### 4. postgres_list_schemas
List all schemas in the database.

**Returns:**
- Schema names
- Schema owners
- Excludes system schemas

## Security Features

### Read-Only Operations
The server enforces strict read-only access:

✅ **Allowed:**
- SELECT statements
- CTEs (WITH clauses)
- Complex queries with JOINs
- Aggregate functions
- Window functions

❌ **Blocked:**
- INSERT operations
- UPDATE operations  
- DELETE operations
- DROP statements
- CREATE statements
- ALTER statements
- TRUNCATE operations
- Transaction control (COMMIT, ROLLBACK)
- Permission changes (GRANT, REVOKE)

### SQL Injection Protection
- Uses parameterized queries where possible
- Validates query syntax before execution
- Proper connection pooling with limits

### Connection Security
- SSL support for encrypted connections
- Connection pooling with timeouts
- Automatic connection cleanup
- Graceful shutdown handling

## Example Queries

### Basic Data Exploration
```sql
-- Get table row counts
SELECT 
  schemaname,
  tablename, 
  n_tup_ins as rows_inserted,
  n_tup_upd as rows_updated,
  n_tup_del as rows_deleted
FROM pg_stat_user_tables 
ORDER BY n_tup_ins DESC;
```

### Complex Analytics
```sql
-- Monthly user registration trend
SELECT 
  DATE_TRUNC('month', created_at) as month,
  COUNT(*) as new_users,
  COUNT(*) OVER (ORDER BY DATE_TRUNC('month', created_at)) as cumulative_users
FROM users 
WHERE created_at >= NOW() - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month;
```

### Data Quality Checks
```sql
-- Find potential data quality issues
SELECT 
  'Missing emails' as issue,
  COUNT(*) as count
FROM users 
WHERE email IS NULL OR email = ''
UNION ALL
SELECT 
  'Duplicate emails' as issue,
  COUNT(*) - COUNT(DISTINCT email) as count  
FROM users;
```

## Troubleshooting

### Connection Issues
1. Verify database credentials in `.env`
2. Check if PostgreSQL server is running
3. Confirm network connectivity
4. Validate SSL settings

### Permission Errors
1. Ensure database user has SELECT privileges
2. Check schema-level permissions
3. Verify table-level access rights

### Query Limitations
1. Large result sets may be truncated for performance
2. Complex queries may have timeout limits
3. Only read-only operations are supported

## Development

### Adding New Tools
1. Add tool definition in `setupToolHandlers()`
2. Implement handler logic
3. Add input validation schema
4. Update documentation

### Testing
```bash
# Test database connection
npm run test-connection

# Build and start server
npm run dev
```

### Debugging
The server logs errors to stderr while maintaining MCP protocol on stdout. Use appropriate logging levels in your MCP client.
