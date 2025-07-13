# Test Infrastructure

This directory contains all testing and development infrastructure for the PostgreSQL MCP Server.

## Structure

```
test/
├── docker/                     # Docker environment
│   ├── docker-compose.yml      # Docker Compose configuration
│   ├── Dockerfile.postgres     # PostgreSQL Docker image
│   └── init-scripts/           # Database initialization scripts
│       ├── 01-create-schema.sql
│       └── 02-insert-test-data.sql
├── scripts/                    # Test automation scripts
│   ├── docker-cleanup.sh       # Docker cleanup utilities
│   ├── start-test-db.sh        # Start test database
│   └── test-complete.sh        # Complete test workflow
├── test-connection.ts          # Database connection test
├── test-mcp-security.ts        # Security validation test
├── test-queries.sql            # Sample queries for testing
└── test-write-protection.ts    # Write protection test
```

## Quick Start

### Run Complete Test Suite
```bash
# From project root
npm run test:complete
# or
./test.sh
```

### Individual Commands
```bash
# Start test database
npm run docker:start

# Run security tests
npm run test-mcp-security

# Clean up Docker resources
npm run docker:clean

# Check Docker status
npm run docker:status
```

## Test Environment

The test environment includes:
- **PostgreSQL 15.13** in Docker container
- **3 schemas**: public, sales, analytics
- **6 tables** with realistic e-commerce data
- **74 total records** across all tables

### Test Data
- 10 users with profiles
- 6 product categories 
- 21 products across categories
- 9 orders with line items
- 15 analytics records

## Security Testing

The test suite validates:
- ✅ SQL injection protection
- ✅ INSERT/UPDATE/DELETE blocking
- ✅ Comment sanitization
- ✅ Case variation attacks
- ✅ Whitespace attacks
- ✅ Data integrity maintenance

## Docker Management

### Available Commands
- `npm run docker:start` - Start test database
- `npm run docker:stop` - Stop containers
- `npm run docker:clean` - Remove all resources
- `npm run docker:reset` - Clean and restart
- `npm run docker:status` - Show current status

### pgAdmin Access (Optional)
```bash
cd test/docker
docker-compose --profile tools up -d pgadmin
```
Then visit: http://localhost:8080
- Email: admin@example.com
- Password: admin

## Development Workflow

1. **Start Development**: `npm run docker:start`
2. **Run Tests**: `npm run test-mcp-security`
3. **Clean Up**: `npm run docker:clean`

The complete workflow automatically handles setup, testing, and cleanup.
