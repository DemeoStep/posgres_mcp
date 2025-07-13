#!/bin/bash

# Docker Test Environment Setup Script

echo "🐳 Setting up PostgreSQL Docker test environment..."
echo ""

# Build and start PostgreSQL container
echo "📦 Building PostgreSQL Docker image..."
docker-compose up -d postgres

echo ""
echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 10

# Check if PostgreSQL is ready
echo "🔍 Checking PostgreSQL health..."
docker-compose exec postgres pg_isready -U testuser -d testdb

if [ $? -eq 0 ]; then
    echo "✅ PostgreSQL is ready!"
    echo ""
    echo "📊 Database Information:"
    echo "  Host: localhost"
    echo "  Port: 5432"
    echo "  Database: testdb"
    echo "  Username: testuser"
    echo "  Password: testpass"
    echo ""
    echo "🗂️  Available Schemas:"
    docker-compose exec postgres psql -U testuser -d testdb -c "\dn"
    echo ""
    echo "📋 Available Tables:"
    docker-compose exec postgres psql -U testuser -d testdb -c "\dt public.*"
    echo ""
    docker-compose exec postgres psql -U testuser -d testdb -c "\dt sales.*"
    echo ""
    docker-compose exec postgres psql -U testuser -d testdb -c "\dt analytics.*"
    echo ""
    echo "🧪 Sample Data Count:"
    docker-compose exec postgres psql -U testuser -d testdb -c "
    SELECT 
        'users' as table_name, COUNT(*) as row_count FROM users
    UNION ALL
    SELECT 
        'sales.products' as table_name, COUNT(*) as row_count FROM sales.products
    UNION ALL
    SELECT 
        'sales.orders' as table_name, COUNT(*) as row_count FROM sales.orders
    UNION ALL
    SELECT 
        'analytics.user_analytics' as table_name, COUNT(*) as row_count FROM analytics.user_analytics
    ORDER BY table_name;
    "
    echo ""
    echo "🎯 Next Steps:"
    echo "  1. Copy test environment: cp .env.test .env"
    echo "  2. Test MCP server: npm run test-connection"
    echo "  3. Start MCP server: npm run dev"
    echo ""
    echo "🧹 Cleanup Commands:"
    echo "  • Stop containers: npm run docker:stop"
    echo "  • Clean everything: npm run docker:clean"
    echo "  • Reset and restart: npm run docker:reset"
    echo "  • Check status: npm run docker:status"
    echo ""
    echo "🔧 Optional: Start pgAdmin for GUI access:"
    echo "  docker-compose --profile tools up -d pgadmin"
    echo "  Then visit: http://localhost:8080"
    echo "  Login: admin@example.com / admin"
    echo ""
else
    echo "❌ PostgreSQL failed to start properly"
    echo "📋 Container logs:"
    docker-compose logs postgres
fi
