CREATE SCHEMA IF NOT EXISTS banking.banking;

CREATE TABLE IF NOT EXISTS banking.banking.branches (
    branch_code        STRING,
    branch_name        STRING,
    city               STRING,
    state              STRING,
    region             STRING,
    created_at         TIMESTAMP
) USING DELTA;

CREATE TABLE IF NOT EXISTS banking.banking.customers (
    customer_id        INT,
    first_name         STRING,
    last_name          STRING,
    date_of_birth      DATE,
    pan_number         STRING,
    email              STRING,
    phone_number       STRING,
    kyc_status         STRING,
    branch_code        STRING,
    created_at         TIMESTAMP,
    updated_at         TIMESTAMP
) USING DELTA;

CREATE TABLE IF NOT EXISTS banking.banking.accounts (
    account_id         BIGINT,
    customer_id        INT,
    account_type       STRING,
    balance            DECIMAL(18,2),
    currency           STRING,
    branch_code        STRING,
    status             STRING,
    opened_date        DATE,
    created_at         TIMESTAMP,
    updated_at         TIMESTAMP
) USING DELTA;

CREATE TABLE IF NOT EXISTS banking.banking.transactions (
    txn_id             BIGINT,
    account_id         BIGINT,
    txn_type           STRING,
    amount             DECIMAL(18,2),
    txn_timestamp      TIMESTAMP,
    channel            STRING,
    status             STRING,
    created_at         TIMESTAMP
) USING DELTA;