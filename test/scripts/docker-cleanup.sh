#!/bin/bash

# Docker cleanup script for PostgreSQL MCP Server

echo "🧹 PostgreSQL MCP Server - Docker Cleanup"
echo "=========================================="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$SCRIPT_DIR/../docker"

# Function to show current Docker status
show_status() {
    echo "📊 Current Docker Status:"
    echo "------------------------"
    
    echo "🐳 Running Containers:"
    docker ps --filter "name=postgres-mcp" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  No MCP containers running"
    
    echo ""
    echo "💾 Volumes:"
    docker volume ls --filter "name=posgres_mcp" --format "table {{.Name}}\t{{.Size}}" 2>/dev/null || echo "  No MCP volumes found"
    
    echo ""
    echo "🌐 Networks:"
    docker network ls --filter "name=posgres_mcp" --format "table {{.Name}}\t{{.Driver}}" 2>/dev/null || echo "  No MCP networks found"
    
    echo ""
}

# Function for soft cleanup (stop containers)
soft_cleanup() {
    echo "🛑 Stopping containers..."
    cd "$DOCKER_DIR" && docker-compose down
    
    if [ $? -eq 0 ]; then
        echo "✅ Containers stopped successfully"
    else
        echo "⚠️  Some containers may not have stopped properly"
    fi
}

# Function for hard cleanup (remove everything)
hard_cleanup() {
    echo "🗑️  Performing hard cleanup (removing containers, volumes, and networks)..."
    cd "$DOCKER_DIR" && docker-compose down -v --remove-orphans
    
    # Remove any dangling images
    echo "🖼️  Removing unused images..."
    docker image prune -f --filter "label=com.docker.compose.project=posgres_mcp" 2>/dev/null
    
    # Remove any leftover volumes
    echo "💾 Removing project volumes..."
    docker volume rm posgres_mcp_postgres_data 2>/dev/null || echo "  Volume already removed or doesn't exist"
    
    # Remove network
    echo "🌐 Removing project network..."
    docker network rm posgres_mcp_mcp-network 2>/dev/null || echo "  Network already removed or doesn't exist"
    
    if [ $? -eq 0 ]; then
        echo "✅ Hard cleanup completed successfully"
    else
        echo "⚠️  Some resources may not have been removed (they might not exist)"
    fi
}

# Function to reset and restart
reset_and_restart() {
    echo "🔄 Resetting and restarting the test environment..."
    hard_cleanup
    echo ""
    echo "🚀 Starting fresh environment..."
    "$SCRIPT_DIR/start-test-db.sh"
}

# Main menu
case "${1:-}" in
    "status")
        show_status
        ;;
    "stop")
        echo "🛑 Stopping PostgreSQL MCP containers..."
        soft_cleanup
        ;;
    "clean")
        echo "🧹 Cleaning up PostgreSQL MCP Docker resources..."
        hard_cleanup
        ;;
    "reset")
        echo "🔄 Resetting PostgreSQL MCP test environment..."
        reset_and_restart
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  status    Show current Docker status"
        echo "  stop      Stop running containers (soft cleanup)"
        echo "  clean     Remove containers, volumes, and networks (hard cleanup)"
        echo "  reset     Clean everything and restart fresh"
        echo "  help      Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 status   # Check what's running"
        echo "  $0 stop     # Stop containers but keep data"
        echo "  $0 clean    # Remove everything"
        echo "  $0 reset    # Clean and restart fresh"
        ;;
    "")
        echo "🤔 What would you like to do?"
        echo ""
        echo "1. Show status"
        echo "2. Stop containers (keep data)"
        echo "3. Clean everything (remove data)"
        echo "4. Reset and restart fresh"
        echo "5. Exit"
        echo ""
        read -p "Choose an option (1-5): " choice
        
        case $choice in
            1)
                show_status
                ;;
            2)
                soft_cleanup
                ;;
            3)
                echo ""
                echo "⚠️  WARNING: This will remove all test data!"
                read -p "Are you sure? (y/N): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    hard_cleanup
                else
                    echo "❌ Cleanup cancelled"
                fi
                ;;
            4)
                echo ""
                echo "⚠️  WARNING: This will remove all test data and restart fresh!"
                read -p "Are you sure? (y/N): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    reset_and_restart
                else
                    echo "❌ Reset cancelled"
                fi
                ;;
            5)
                echo "👋 Goodbye!"
                exit 0
                ;;
            *)
                echo "❌ Invalid option"
                exit 1
                ;;
        esac
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac

echo ""
show_status
