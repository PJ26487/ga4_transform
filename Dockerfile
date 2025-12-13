# Use Python 3.11 slim image as base
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install dbt-duckdb adapter
RUN pip install --no-cache-dir dbt-core dbt-duckdb

# Copy project files
COPY extraction_db.py .
COPY config.yaml .
COPY ga4_transform/ ./ga4_transform/

# Create directories for logs and data
RUN mkdir -p logs ga4_transform/logs ga4_transform/target

# --- CHANGED SECTION START ---
# Copy entrypoint script to current directory (.) instead of root (/)
COPY run_pipeline.sh .

# Create dbt profiles directory
RUN mkdir -p /root/.dbt

# Fix Windows line endings and make executable
# (Now this works because the file is in the current directory)
RUN sed -i 's/\r$//' run_pipeline.sh && chmod +x run_pipeline.sh

# Default command (changed to look in current directory)
CMD ["./run_pipeline.sh"]
# --- CHANGED SECTION END ---