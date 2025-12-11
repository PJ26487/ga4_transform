#!/bin/bash

set -e  # Exit on any error

echo "=========================================="
echo "GA4 BigQuery to DuckDB ETL Pipeline"
echo "=========================================="
echo ""

# Check if .env file exists
if [ ! -f /app/.env ]; then
    echo "[ERROR] .env file not found!"
    echo "Please create a .env file with your Google Cloud service account credentials."
    echo "See env.example for reference."
    exit 1
fi

# Check if config.yaml exists
if [ ! -f /app/config.yaml ]; then
    echo "[ERROR] config.yaml file not found!"
    exit 1
fi

echo "[STEP 1/2] Extracting data from BigQuery to DuckDB..."
echo ""

# Run extraction script
python /app/extraction_db.py

if [ $? -ne 0 ]; then
    echo "[ERROR] Extraction failed!"
    exit 1
fi

echo ""
echo "[STEP 2/2] Running dbt transformations..."
echo ""

# Change to dbt project directory
cd /app/ga4_transform

# Run dbt build
dbt build --profiles-dir /root/.dbt

if [ $? -ne 0 ]; then
    echo "[ERROR] dbt transformation failed!"
    exit 1
fi

echo ""
echo "=========================================="
echo "Pipeline completed successfully! ✅"
echo "=========================================="
echo ""
echo "Your flattened GA4 data is now available in:"
echo "  - Database: /app/ga4_export.duckdb"
echo "  - Tables: events_flattened, device_flattened, geo_flattened, users_flattened, ltv_flattened, privacy_info_flattened"
echo ""
echo "To query the data, use:"
echo "  duckdb /app/ga4_export.duckdb"
echo ""
