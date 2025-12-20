#!/bin/bash

################################################################################
# Initialize Azure Databases (MySQL + CosmosDB)
# Script to set up databases and initial data for the E-Commerce application
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Database Initialization Script${NC}"
echo -e "${YELLOW}════════════════════════════════════════════${NC}"
echo ""

# Load environment variables
if [ ! -f "$(dirname "$0")/../.env" ]; then
    echo -e "${RED}❌ .env file not found in Devops/${NC}"
    exit 1
fi

source "$(dirname "$0")/../.env"

# Verify required variables
required_vars=(
    "MYSQL_SERVER"
    "MYSQL_USER"
    "MYSQL_PASSWORD"
    "COSMOSDB_CONNECTION_STRING"
    "COSMOSDB_ACCOUNT_NAME"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ Required environment variable not set: $var${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✓ All environment variables loaded${NC}"
echo ""

################################################################################
# 1. Initialize MySQL Databases
################################################################################
echo -e "${YELLOW}1️⃣  Initializing MySQL Databases...${NC}"

# Create databases
mysql -h "$MYSQL_SERVER" \
    -u "$MYSQL_USER" \
    -p"$MYSQL_PASSWORD" \
    --enable-cleartext-plugin \
    -e "
    -- Create databases if not exist
    CREATE DATABASE IF NOT EXISTS ecomdb;
    CREATE DATABASE IF NOT EXISTS ecom_order_db;
    CREATE DATABASE IF NOT EXISTS ecom_inventory_db;
    
    USE ecomdb;
    -- Tables for product-service will be created by JPA
    
    USE ecom_order_db;
    -- Tables for order-service will be created by JPA
    
    USE ecom_inventory_db;
    -- Tables for inventory-service will be created by JPA
    
    SHOW DATABASES;
    "

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ MySQL databases initialized successfully${NC}"
else
    echo -e "${RED}❌ Failed to initialize MySQL databases${NC}"
    exit 1
fi

echo ""

################################################################################
# 2. Initialize CosmosDB (MongoDB)
################################################################################
echo -e "${YELLOW}2️⃣  Initializing CosmosDB (MongoDB)...${NC}"

# Using Azure CLI to create collections in CosmosDB
az cosmosdb mongodb database exists \
    --account-name "$COSMOSDB_ACCOUNT_NAME" \
    --name "ecom-mongo-db"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ CosmosDB database already exists${NC}"
else
    echo -e "${YELLOW}Creating CosmosDB database...${NC}"
    
    az cosmosdb mongodb database create \
        --account-name "$COSMOSDB_ACCOUNT_NAME" \
        --name "ecom-mongo-db" \
        --resource-group "$RESOURCE_GROUP" \
        --throughput 400
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ CosmosDB database created${NC}"
    else
        echo -e "${RED}❌ Failed to create CosmosDB database${NC}"
        exit 1
    fi
fi

# Collections for MongoDB will be created by Spring Data MongoDB
echo -e "${GREEN}✓ MongoDB collections will be created by Spring Data${NC}"

echo ""

################################################################################
# 3. Verify Connectivity
################################################################################
echo -e "${YELLOW}3️⃣  Verifying Database Connectivity...${NC}"

# Test MySQL connectivity
echo -n "Testing MySQL connection... "
mysql -h "$MYSQL_SERVER" \
    -u "$MYSQL_USER" \
    -p"$MYSQL_PASSWORD" \
    --enable-cleartext-plugin \
    -e "SELECT 'MySQL Connected' AS status;" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌${NC}"
    exit 1
fi

# Test CosmosDB connectivity
echo -n "Testing CosmosDB connection... "
az cosmosdb check-name-exists \
    --account-name "$COSMOSDB_ACCOUNT_NAME" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌${NC}"
    exit 1
fi

echo ""

################################################################################
# 4. Summary
################################################################################
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Database Initialization Complete${NC}"
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo ""
echo "Initialized resources:"
echo "  • MySQL Databases:"
echo "    - ecomdb (product-service)"
echo "    - ecom_order_db (order-service)"
echo "    - ecom_inventory_db (inventory-service)"
echo "  • CosmosDB Account: $COSMOSDB_ACCOUNT_NAME"
echo "  • CosmosDB Database: ecom-mongo-db"
echo ""
echo "Next steps:"
echo "  1. Deploy services using Helm"
echo "  2. Services will auto-create tables via JPA/MongoDB driver"
echo "  3. Monitor logs: kubectl logs -f <pod-name> -n backend"
echo ""
