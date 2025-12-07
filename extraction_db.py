import pandas as pd
import numpy as np
from dotenv import load_dotenv
from google.cloud import bigquery
import logging 
import os
import duckdb
import dbt
import json
from google.oauth2 import service_account
import yaml
import datetime 
from datetime import datetime, timedelta
import pyarrow as pa

print('libraries imported')

def extracting_start_end_dates(config):
    if config['date_range']['type'] == 'date_range':
        start_date = config['date_range']['start_date']
        end_date = config['date_range']['end_date']
        # making sure that the end_date is larger than the start_date
        if start_date < end_date:
            print(f'dates extracted as: from {start_date} to {end_date}')
        else:
            print('Your start date should be smaller than the end date')
    
    elif config['date_range']['type'] == 'days':
        end_date = config['date_range']['end_date']
        start_date = end_date - timedelta(days=config['date_range']['max_days_extraction'])
        print(f'dates extracted as: from {start_date} to {end_date}')
    
    return start_date, end_date

def ensure_duckdb_exists(db_path):
    if not os.path.exists(db_path):
        print(f"[INFO] DuckDB database not found. Creating: {db_path}")
        duckdb.connect(db_path).close()
    else:
        print(f"[INFO] DuckDB database found: {db_path}")

# creating a simple function to extract the bigquery file
def extract_push_bigquery(start_date, end_date, bigquery_client, config):
    print('Extracting data from BigQuery...')
    start_date_bq = datetime.strftime(start_date, '%Y%m%d')
    end_date_bq = datetime.strftime(end_date,'%Y%m%d')

    project_id = config['bigquery']['project_id']
    dataset = config['bigquery']['dataset']   
    duckdb_path = config['output']['duckdb_file']
    table_name = config['output']['table_name']
    
    query = f"""
    SELECT *
    FROM `{project_id}.{dataset}.events_*`
    WHERE _TABLE_SUFFIX BETWEEN '{start_date_bq}' AND '{end_date_bq}'
    """

    # Run the query first to get total rows
    query_job = bigquery_client.query(query)
    result = query_job.result()
    
    # THIS IS THE KEY LINE - shows you total rows
    total_rows = result.total_rows
    print(f'[INFO] Total rows to process: {total_rows:,}')
    print(f'[INFO] Batch size: 50,000')
    print(f'[INFO] Expected batches: ~{total_rows // 50000 + 1}')
    
    # connecting to duckdb 
    conn = duckdb.connect(duckdb_path)
    
    # always drop the old table if exists
    conn.execute(f'drop table if exists {table_name}')

    # Get iterator AFTER checking total rows
    iterator = result.to_arrow_iterable()

    batch_count = 0
    rows_processed = 0

    for batch in iterator:
        batch_count += 1
        rows_in_batch = len(batch)
        rows_processed += rows_in_batch
        
        # Better progress message
        progress_pct = (rows_processed / total_rows) * 100
        print(f'[BATCH {batch_count}] Processing {rows_in_batch:,} rows | Total: {rows_processed:,}/{total_rows:,} ({progress_pct:.1f}%)')
        
        if batch_count == 1:
            conn.register("batch_table", batch)
            conn.execute(f'create table {table_name} as select * from batch_table')
        else:
            conn.register("batch_table", batch)
            conn.execute(f'insert into {table_name} select * from batch_table')

    conn.close()
    print(f'[SUCCESS] Inserted {rows_processed:,} rows into DuckDB')
        

def main():
    # getting the json keys from the dotenv environment 
    load_dotenv()
    key = os.getenv('key')
    json_key = json.loads(key)

    # loading the yaml file 
    with open("config.yaml", "r") as f:
        config = yaml.safe_load(f)

    # create the authentication clients using the json objects 
    credentials = service_account.Credentials.from_service_account_info(json_key)
    bigquery_client = bigquery.Client(credentials=credentials)
    print('the clients have been created')

    # extracting the yaml file contents
    db_path = config['output']['duckdb_file']
    table_raw = config['output']['table_name']
    project_id = config['bigquery']['project_id']
    merge_type = config['output']['merge_type']
    dataset = config['bigquery']['dataset']
    max_days_extraction = config['date_range']['max_days_extraction']

    print(max_days_extraction)

    with open("config.yaml", "r") as f:
        config = yaml.safe_load(f)
    start_date, end_date = extracting_start_end_dates(config)

    print(start_date)
    print(end_date)

    # ensuring the db is created
    ensure_duckdb_exists(db_path)

    # once completed we move onto pushing the data here
    extract_push_bigquery(start_date,end_date,bigquery_client,config)

if __name__ == "__main__":

    main()

