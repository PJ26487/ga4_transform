# GA4 BigQuery to DuckDB ETL Pipeline

A production-ready ETL pipeline that extracts Google Analytics 4 (GA4) event data from BigQuery, transforms it using dbt, and loads it into DuckDB for fast analytical queries. This solution is designed for data analysts who need clean, flattened GA4 data without managing complex infrastructure.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start (Docker)](#quick-start-docker)
- [Manual Setup](#manual-setup)
- [Configuration](#configuration)
- [Usage](#usage)
- [Output Schema](#output-schema)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Overview

This pipeline automates the extraction and transformation of GA4 data through two main stages:

1. **Extraction**: Pulls GA4 events data from BigQuery (with date range filtering) and loads it into DuckDB using efficient batch processing
2. **Transformation**: Flattens nested GA4 JSON structures into relational tables using dbt, making the data analyst-friendly

### Key Features

- ✅ **One-Button Execution**: Complete pipeline runs via Docker Compose
- ✅ **Batch Processing**: Handles large datasets efficiently with 50,000 row batches
- ✅ **Flexible Date Ranges**: Supports both absolute date ranges and relative day-based extraction
- ✅ **Automated Flattening**: Transforms 6+ nested GA4 structures into flat tables
- ✅ **Progress Tracking**: Real-time progress indicators during extraction
- ✅ **Production Ready**: Includes error handling, logging, and configuration management

## Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐      ┌──────────────┐
│   BigQuery  │─────▶│  Extraction  │─────▶│   DuckDB    │─────▶│  dbt Transform│
│  (GA4 Data) │      │   (Python)   │      │  (Raw Data) │      │  (Flattened) │
└─────────────┘      └──────────────┘      └─────────────┘      └──────────────┘
```

### Pipeline Components

- **`extraction_db.py`**: Python script that extracts data from BigQuery using the Google Cloud BigQuery client
- **`ga4_transform/`**: dbt project containing SQL models that flatten nested GA4 structures
- **`config.yaml`**: Configuration file for date ranges, BigQuery connection, and output settings
- **Docker Setup**: Containerized environment for consistent execution across systems

## Prerequisites

### For Docker Setup (Recommended)

- Docker Desktop installed ([Download](https://www.docker.com/products/docker-desktop))
- Docker Compose (included with Docker Desktop)

### For Manual Setup

- Python 3.8+ 
- Google Cloud service account with BigQuery access
- BigQuery dataset with GA4 export data

## Quick Start (Docker)

This is the fastest way to get started. The entire pipeline runs with a single command.

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd bq_flatten_duckdb_v3
```

### Step 2: Configure Environment

1. Create a `.env` file from the template:
   ```bash
   cp env.example .env
   ```

2. Edit `.env` and add your Google Cloud service account JSON credentials:
   ```bash
   key='{"type": "service_account", "project_id": "your-project", ...}'
   ```
   
   > **Note**: The `key` variable should contain the entire service account JSON as a single-line string. You can copy the JSON from your service account key file.

3. Update `config.yaml` with your BigQuery project and dataset:
   ```yaml
   bigquery:
     project_id: your-project-id
     dataset: your-ga4-dataset
   ```

4. Verify `profiles.yml` exists in the project root (already provided):
   ```yaml
   ga4_transform:
     target: dev
     outputs:
       dev:
         type: duckdb
         path: /app/ga4_export.duckdb
         schema: main
   ```

### Step 3: Run the Pipeline

Execute the complete pipeline:

```bash
docker-compose up --build
```

This will:
1. Build the Docker image with all dependencies
2. Extract data from BigQuery to DuckDB
3. Run dbt transformations
4. Produce flattened tables ready for analysis

### Step 4: Access Your Data

The DuckDB database (`ga4_export.duckdb`) will be available in the project directory. You can query it using:

- **DuckDB CLI**: `duckdb ga4_export.duckdb`
- **Python**: `duckdb.connect('ga4_export.duckdb')`
- **Any SQL client** that supports DuckDB

## Manual Setup

If you prefer to run without Docker:

### Step 1: Create Virtual Environment

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### Step 2: Install Dependencies

```bash
pip install -r requirements.txt
```

### Step 3: Configure dbt Profile

Create `~/.dbt/profiles.yml` (or `%USERPROFILE%\.dbt\profiles.yml` on Windows):

```yaml
ga4_transform:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: ga4_export.duckdb
      schema: main
```

### Step 4: Set Environment Variables

Create a `.env` file in the project root:

```bash
key='<your-service-account-json-as-string>'
```

### Step 5: Run Pipeline

```bash
# Extract data
python extraction_db.py

# Transform data
cd ga4_transform
dbt build
```

## Configuration

### `config.yaml`

The main configuration file controls data extraction parameters:

```yaml
# Date range configuration
date_range:
  type: date_range  # Options: "date_range" or "days"
  start_date: 2021-01-28  # Required if type is "date_range"
  end_date: 2021-01-29
  max_days_extraction: 10  # Used if type is "days"

# BigQuery connection
bigquery:
  project_id: your-project-id
  dataset: your-ga4-dataset

# Output configuration
output:
  duckdb_file: ga4_export.duckdb
  table_name: ga4_raw
  merge_type: replace  # Options: "replace" (drops existing table)
```

### Date Range Types

- **`date_range`**: Extract data between specific dates (e.g., `2021-01-28` to `2021-01-29`)
- **`days`**: Extract data for the last N days from `end_date` (e.g., last 10 days)

## Usage

### Extraction Process

The extraction script (`extraction_db.py`) performs the following:

1. Validates date range configuration
2. Connects to BigQuery using service account credentials
3. Queries GA4 events tables with date filtering
4. Processes results in batches of 50,000 rows
5. Loads data into DuckDB with progress tracking

**Example Output:**
```
[INFO] Total rows to process: 1,234,567
[INFO] Batch size: 50,000
[BATCH 1] Processing 50,000 rows | Total: 50,000/1,234,567 (4.0%)
[BATCH 2] Processing 50,000 rows | Total: 100,000/1,234,567 (8.1%)
...
[SUCCESS] Inserted 1,234,567 rows into DuckDB
```

### Transformation Models

The dbt project creates the following flattened tables:

| Model | Description | Key Fields |
|-------|-------------|------------|
| `events_flattened` | Event parameters unnest | `event_name`, `param_key`, `param_string_value`, `param_int_value`, `param_double_value` |
| `device_flattened` | Device information | `advertising_id`, `category`, `operating_system`, `mobile_brand_name` |
| `geo_flattened` | Geographic data | `city`, `country`, `continent`, `region`, `sub_continent` |
| `users_flattened` | User properties | `user_properties` unnest with key-value pairs |
| `ltv_flattened` | Lifetime value data | User lifetime value metrics |
| `privacy_info_flattened` | Privacy information | Privacy settings and compliance data |

## Output Schema

### Raw Table: `ga4_raw`

Contains the raw GA4 events data as extracted from BigQuery, preserving the original nested structure.

### Flattened Tables

All flattened tables are materialized as tables in DuckDB and include:
- `event_date`: Date of the event (YYYYMMDD)
- `event_timestamp`: Microsecond timestamp
- `event_name`: Name of the GA4 event
- `user_pseudo_id`: Pseudonymous user identifier
- `user_id`: User identifier (if available)

## Troubleshooting

### Common Issues

#### 1. Authentication Errors

**Problem**: `google.auth.exceptions.DefaultCredentialsError`

**Solution**: 
- Verify your `.env` file contains a valid `key` variable
- Ensure the service account JSON is properly formatted (single-line string)
- Check that the service account has BigQuery Data Viewer role

#### 2. BigQuery Dataset Not Found

**Problem**: `google.api_core.exceptions.NotFound: 404 Dataset not found`

**Solution**:
- Verify `project_id` and `dataset` in `config.yaml` are correct
- Ensure the dataset exists in your BigQuery project
- Check that GA4 export is enabled for the dataset

#### 3. DuckDB Connection Issues in dbt

**Problem**: `dbt.exceptions.DbtRuntimeError: Could not connect to database`

**Solution**:
- Ensure `profiles.yml` points to the correct DuckDB file path
- Verify the DuckDB file was created during extraction
- Check that the file path is absolute or relative to dbt working directory

#### 4. Memory Issues with Large Datasets

**Problem**: Pipeline fails on large date ranges

**Solution**:
- Reduce `max_days_extraction` in `config.yaml`
- Split extraction into smaller date ranges
- Increase Docker memory allocation (Docker Desktop → Settings → Resources)

### Getting Help

- Check the logs: `logs/dbt.log` and console output
- Verify configuration: Ensure `config.yaml` and `.env` are correctly formatted
- Test connectivity: Run `python -c "from google.cloud import bigquery; print('OK')"` to verify BigQuery access

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

[Add your license here]

## Support

For questions or issues, please open an issue on the repository or contact [your team/support channel].

---

**Built for analysts, by analysts.** 🚀