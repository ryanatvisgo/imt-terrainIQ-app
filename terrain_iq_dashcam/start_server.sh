#!/bin/bash

# Kill any existing mock server processes
echo "🔄 Stopping existing mock server..."
pkill -f "node.*server.js" 2>/dev/null || echo "   No existing server found"

# Wait a moment for the process to terminate
sleep 1

# Start the mock server
echo "🚀 Starting mock server on port 3000..."
cd mock_server && node server.js
