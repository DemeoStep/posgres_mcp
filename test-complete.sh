#!/bin/bash

# Complete test workflow for PostgreSQL MCP Server

echo "🧪 PostgreSQL MCP Server - Complete Test Workflow"
echo "================================================="
echo ""

# Step 1: Setup test database
echo "📦 Step 1: Setting up test database..."
./start-test-db.sh

echo ""
echo "⏳ Waiting for database to be fully ready..."
sleep 5

# Step 2: Setup environment
echo "🔧 Step 2: Setting up environment..."
if [ ! -f .env ]; then
    echo "📋 Copying test environment configuration..."
    cp .env.test .env
    echo "✅ Environment configured for testing"
else
    echo "⚠️  .env file already exists, keeping current configuration"
fi

# Step 3: Build MCP server
echo ""
echo "🏗️  Step 3: Building MCP server..."
npm run build

if [ $? -eq 0 ]; then
    echo "✅ MCP server built successfully"
else
    echo "❌ Failed to build MCP server"
    exit 1
fi

# Step 4: Test database connection
echo ""
echo "🔌 Step 4: Testing database connection..."
npm run test-connection

if [ $? -eq 0 ]; then
    echo "✅ Database connection successful"
else
    echo "❌ Database connection failed"
    exit 1
fi

# Step 5: Show test data summary
echo ""
echo "📊 Step 5: Test Data Summary"
echo "----------------------------"
docker-compose exec postgres psql -U testuser -d testdb -c "
SELECT 
    schemaname,
    relname as tablename,
    n_tup_ins as row_count
FROM pg_stat_user_tables 
ORDER BY schemaname, relname;
"

echo ""
echo "🎯 Test Environment Ready!"
echo "========================="
echo ""
echo "📋 Available Test Data:"
echo "  • 10 users with realistic profiles"
echo "  • 6 product categories"
echo "  • 20+ products across categories"
echo "  • 9 orders with line items"
echo "  • User analytics data"
echo ""
echo "🔧 MCP Server Configuration:"
echo "  • Host: localhost:5432"
echo "  • Database: testdb"
echo "  • User: testuser"
echo "  • SSL: disabled"
echo ""
echo "🚀 Next Steps:"
echo "  1. Configure your MCP client with mcp-config.json"
echo "  2. Start MCP server: npm run dev"
echo "  3. Test with sample queries from test-queries.sql"
echo ""
echo "💡 Useful Commands:"
echo "  • View logs: docker-compose logs postgres"
echo "  • Connect directly: docker-compose exec postgres psql -U testuser -d testdb"
echo "  • Stop database: docker-compose down"
echo "  • Clean everything: npm run docker:clean"
echo "  • Reset and restart: npm run docker:reset"
echo "  • Check status: npm run docker:status"
echo "  • Start pgAdmin: docker-compose --profile tools up -d pgadmin"
echo ""

# Step 6: Automatic cleanup
echo "🧹 Step 6: Cleaning up test environment..."
echo "=========================================="
echo ""
echo "🛑 Stopping containers and cleaning up..."
npm run docker:clean
echo ""
echo "✅ Cleanup completed. All containers, volumes, and networks removed."
echo ""
echo "🎉 Test workflow completed!"
echo ""
