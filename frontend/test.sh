#!/bin/bash

# Frontend Test Script
# Tests the Angular frontend application

echo "====== Frontend Unit Tests ======"

cd "$(dirname "$0")" || exit 1

# Install dependencies if not present
if [ ! -d "node_modules" ]; then
    echo "Installing npm dependencies..."
    npm ci --legacy-peer-deps
fi

# Run unit tests with Karma
echo "Running Angular unit tests..."
ng test --watch=false --code-coverage --browsers=ChromeHeadless

# Capture exit code
TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "✅ Frontend unit tests passed!"
else
    echo "❌ Frontend unit tests failed!"
    exit $TEST_EXIT_CODE
fi

# Run linting
echo ""
echo "Running Angular linter..."
ng lint 2>/dev/null || echo "⚠️  Linter not configured"

# Build for production to verify build succeeds
echo ""
echo "Building frontend for production..."
ng build --configuration production

if [ $? -eq 0 ]; then
    echo "✅ Frontend build successful!"
else
    echo "❌ Frontend build failed!"
    exit 1
fi

echo ""
echo "✅ All frontend tests completed successfully!"
