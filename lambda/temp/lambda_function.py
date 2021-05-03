import json
import boto3
import time
import psycopg2
from botocore.exceptions import ClientError
db_connection = psycopg2.connect(
    host="jimbocluster.czvnlhhlsfhv.us-east-1.redshift.amazonaws.com",
    port = 5439,
    database="dev",
    user="awsuser",
    password="Admin123")
iam_role = "arn:aws:iam::074439742463:role/redshift_s3_role"
redshift_cursor = db_connection.cursor()
AWS_REGION = "eu-west-1"
def create_staging_table(staging_table_name):
    table_name = staging_table_name.split('.')[-1]
    table_name = table_name.split('_')
    print(f'{table_name[0]}_{table_name[1]}')
    if f'{table_name[0]}_{table_name[1]}' == 'user_events':
        create_query = f"create table {staging_table_name}( \
            request_id CHAR(36) NOT NULL, \
            request_timestamp TIMESTAMP WITHOUT TIME ZONE NOT NULL, \
            cookie_id CHAR(36) NOT NULL, \
            topic VARCHAR(1024) NOT NULL, \
            message VARCHAR(3128), \
            environment VARCHAR(30), \
            website_id CHAR(36), \
            user_account_id CHAR(36),\
            location VARCHAR(5000), \
            user_agent VARCHAR(1024), \
            referrer VARCHAR(500))"
    else:
        create_query = f"create table {staging_table_name}( \
            request_id VARCHAR(56) NOT NULL  ENCODE zstd, \
            source VARCHAR(255) NOT NULL  ENCODE zstd, \
            medium VARCHAR(255) NOT NULL  ENCODE zstd, \
            campaign VARCHAR(255)   ENCODE zstd, \
            content VARCHAR(255)   ENCODE zstd, \
            term VARCHAR(255)   ENCODE zstd, \
            matchtype VARCHAR(255)   ENCODE zstd, \
            network VARCHAR(255)   ENCODE zstd, \
            ad_id VARCHAR(255)   ENCODE zstd, \
            ad_pos VARCHAR(255)   ENCODE zstd, \
            placement VARCHAR(255)   ENCODE zstd, \
            placement_category VARCHAR(255)   ENCODE zstd, \
            testgroup VARCHAR(255)   ENCODE zstd, \
            device VARCHAR(255)   ENCODE zstd)"
    # redshift_cursor.execute("ROLLBACK")
    redshift_cursor.execute(create_query)
def copy_data_to_staging(s3_bucket, key, staging_table_name):
    copy_query = f"copy {staging_table_name} from 's3://{s3_bucket}/{key}' \
    IGNOREHEADER 1 \
    iam_role '{iam_role}'\
    csv \
    DELIMITER ',';"
    # redshift_cursor.execute("ROLLBACK")
    redshift_cursor.execute(copy_query)
#     # db_connection.commit()
def delete_updated_records(staging_table_name, table_name):
    print(table_name, staging_table_name, "6"* 20)
    delete_query = f"delete from {table_name} using {staging_table_name} \
    where {table_name}.request_id = {staging_table_name}.request_id"
    # redshift_cursor.execute("ROLLBACK")
    redshift_cursor.execute(delete_query)
#     # db_connection.commit()
def insert_records_to_revenue_table(staging_table_name, table_name):
    print(staging_table_name, table_name, "5"*20)
    insert_query = f"insert into {table_name} \
    select * from {staging_table_name};"
    # redshift_cursor.execute("ROLLBACK")
    redshift_cursor.execute(insert_query)
    # db_connection.commit()
def lambda_handler(event, context):
    try:
        s3_bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        print(s3_bucket, key)
        staging_table_name = f"dev.tracking.{key.split('/')[-1]}"
        table_name = f"dev.tracking.{key.split('/')[0].split('_')[-1]}"
        redshift_cursor.execute("begin transaction;")
        create_staging_table(staging_table_name)
        copy_status = copy_data_to_staging(s3_bucket, key, staging_table_name)
        delete_updated_records(staging_table_name, table_name)
        insert_records_to_revenue_table(staging_table_name, table_name)
        redshift_cursor.execute("end transaction;")
        redshift_cursor.execute(f"drop table {staging_table_name};")
        db_connection.commit()
    except Exception as e:
        redshift_cursor.execute("ROLLBACK;")
        raise e
    return True
