/*
================================================================================
Script: Silver Layer Data Quality Checks — bronze.core_tm_sl_aggregates
================================================================================
Script Purpose:
    This script performs data quality and profiling checks on the raw TM SL
    Aggregates table in the 'bronze' schema before transformation into the
    'silver' schema. It performs the following checks per column:
    - a. transaction_posting_date : NULLs, dates before 2020, future dates
    - b. transaction_code         : NULLs, distinct values, duplicate counts
    - c. total_amount_dr          : NULLs, negative values
    - d. total_amount_cr          : NULLs, negative values
    - e. reversal_flag_0          : NULLs, negative values
    - f. reversal_flag_1          : NULLs, negative values

Scope:
    TM SL Aggregates (bronze.core_tm_sl_aggregates) — December 2025.
    Data sourced from the Core Banking lakehouse via Data Hub.
    Expected to be clean — checks serve as validation confirmation.

Usage:
    Run before executing the Silver Layer transformation script.
    Use findings to validate cleansing logic in silver.core_tm_sl_aggregates.
================================================================================
*/

-- a. transaction_posting_date: date > today, date not before 2020, null

SELECT 
*
FROM bronze.core_tm_sl_aggregates
WHERE transaction_posting_date IS NULL 
OR transaction_posting_date < '2020-01-01' 
OR transaction_posting_date > GETDATE()


-- b. transaction_code: null, distinct, count

SELECT DISTINCT
transaction_code
FROM bronze.core_tm_sl_aggregates

SELECT 
transaction_code,
COUNT(*)
FROM bronze.core_tm_sl_aggregates
GROUP BY transaction_code
HAVING COUNT(*) > 1

SELECT 
transaction_code
FROM bronze.core_tm_sl_aggregates
WHERE transaction_code IS NULL

-- c. total_amount_dr: negatives, nulls

SELECT 
total_amount_dr
FROM bronze.core_tm_sl_aggregates
WHERE total_amount_dr < 0 OR total_amount_dr IS NULL

-- d. total_amount_cr: negatives, nulls

SELECT 
total_amount_cr
FROM bronze.core_tm_sl_aggregates
WHERE total_amount_cr < 0 OR total_amount_cr IS NULL

-- e. reversal_flag_0: negatives, nulls

SELECT 
*
FROM bronze.core_tm_sl_aggregates
WHERE reversal_flag_0 < 0 OR reversal_flag_0 IS NULL

-- f. reversal_flag_1

SELECT 
*
FROM bronze.core_tm_sl_aggregates
WHERE reversal_flag_1 < 0 OR reversal_flag_1 IS NULL



