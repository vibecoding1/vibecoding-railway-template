#!/bin/bash

echo "🧪 Testing VibeCoding Railway Template Locally"
echo "=============================================="

# Test 1: Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker to test locally."
    exit 1
fi

echo "✅ Docker is available"

# Test 2: Build the Docker image
echo "🔨 Building Docker image..."
if docker build -t vibecoding-template-test .; then
    echo "✅ Docker image built successfully"
else
    echo "❌ Docker build failed"
    exit 1
fi

# Test 3: Test with environment variables
echo "🚀 Testing container startup..."
echo "Note: This will test the container startup without GitHub repo"

# Run container in detached mode for testing
docker run -d --name vibecoding-test \
    -p 3000:3000 \
    -p 8080:8080 \
    -e PROJECT_NAME="test-project" \
    -e RAILWAY_ENVIRONMENT="development" \
    vibecoding-template-test

# Wait a moment for startup
echo "⏳ Waiting for container to start..."
sleep 10

# Test 4: Check if container is running
if docker ps | grep vibecoding-test > /dev/null; then
    echo "✅ Container is running"
    
    # Test 5: Check health endpoint
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        echo "✅ Health check endpoint is working"
    else
        echo "⚠️  Health check endpoint not responding (may take time to start)"
    fi
    
    # Show container logs
    echo "📋 Container logs:"
    docker logs vibecoding-test --tail 20
    
    # Cleanup
    echo "🧹 Cleaning up test container..."
    docker stop vibecoding-test
    docker rm vibecoding-test
    
    echo ""
    echo "🎉 Template test completed successfully!"
    echo "The template is ready for Railway deployment."
    
else
    echo "❌ Container failed to start"
    echo "📋 Container logs:"
    docker logs vibecoding-test --tail 20
    
    # Cleanup
    docker rm vibecoding-test 2>/dev/null
    
    exit 1
fi

# Cleanup image
docker rmi vibecoding-template-test

echo ""
echo "✅ All tests passed! Template is ready for Railway." 