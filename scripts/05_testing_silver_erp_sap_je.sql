/*
================================================================================
Script: Silver Layer Data Quality Checks — bronze.erp_sap_je
================================================================================
Script Purpose:
    This script performs data quality and profiling checks on the raw SAP
    Journal Entries table in the 'bronze' schema before transformation into
    the 'silver' schema. It performs the following checks per column:
    - a. cleared_open_items_symbol : Distinct values, NULLs, counts
    - b. company_code              : NULLs, distinct values
    - c. account                   : NULLs, length validation (7 digits), counts
    - d. document_number           : NULLs, duplicates, specific value lookup
    - e. document_type             : Distinct values, NULLs, counts
    - f. document_date             : Prior period dates, future dates, NULLs
    - g. reference_key_3           : Counts, length validation (16 chars)
    - h. amount_in_local_currency  : Comma-formatted strings, NULLs, quotes
    - i. local_currency            : NULLs, non-PHP currencies
    - j. tax_code                  : Distinct values, counts
    - k. clearing_document         : Distinct values, length validation (10 chars)
    - m. profit_center             : Distinct values, length validation (3 chars)
    - n. cost_center               : Distinct values, length validation (3 chars)
    - o. transaction_code          : Distinct values, counts, NULLs

Scope:
    SAP Journal Entries (bronze.erp_sap_je) — all accounts, full December 2025.
    Bank Reconciliation and account-level filtering are handled in later layers.

Usage:
    Run before executing the Silver Layer transformation script.
    Use findings to validate cleansing logic in silver.erp_sap_je.
================================================================================
*/

-- a. cleared_open_items_symbol: check values, check for NULLS, DISTINCT
SELECT 
	cleared_open_items_symbol,
	COUNT(*)
FROM bronze.erp_sap_je
GROUP BY cleared_open_items_symbol
HAVING COUNT(*) > 1

SELECT
*
FROM bronze.erp_sap_je
WHERE cleared_open_items_symbol = '@01\QPosted@'

-- b. company_code: Check for distinct values and NULLS
SELECT
*
FROM bronze.erp_sap_je
WHERE company_code IS NULL

-- c. account: check groupings, distincts, count for each

SELECT
*
FROM bronze.erp_sap_je
WHERE account IS NULL OR LEN(account) != 7

SELECT
account,
COUNT(*)
FROM bronze.erp_sap_je
GROUP BY account
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC

-- d. document_number: Check count, nulls, same values of the same doc number

SELECT
document_number,
COUNT(*)
FROM bronze.erp_sap_je
GROUP BY document_number
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC

SELECT
*
FROM bronze.erp_sap_je
WHERE document_number IS NULL

SELECT
*
FROM bronze.erp_sap_je
WHERE document_number = '2300007581'

-- e. document type: distinct, count, nulls

SELECT DISTINCT
document_type
FROM bronze.erp_sap_je

SELECT
*
FROM bronze.erp_sap_je
WHERE document_type IS NULL

SELECT
document_type,
COUNT(*)
FROM bronze.erp_sap_je
GROUP BY document_type
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC

SELECT
*
FROM bronze.erp_sap_je
WHERE document_type IS NOT NULL

-- f. document_date: date more than present, null
SELECT
*
FROM bronze.erp_sap_je
WHERE document_date < '2025-01-01'

SELECT
*
FROM bronze.erp_sap_je
WHERE document_date > GETDATE()

SELECT *
FROM bronze.erp_sap_je
WHERE posting_date IS NULL

--g. reference_key_3: distinct, count, len | NEED TO CLARIFY ref key purpose

SELECT reference_key_3,
COUNT(*) 
FROM bronze.erp_sap_je
GROUP BY reference_key_3
HAVING COUNT(*) > 1


SELECT
*
FROM bronze.erp_sap_je
WHERE LEN(reference_key_3) != 16 OR reference_key_3 IS NULL

SELECT TOP 100 *
FROM bronze.erp_sap_je
WHERE LEN(reference_key_3) != 16

-- h. amount_in_local_currency
SELECT
*
FROM bronze.erp_sap_je
WHERE amount_in_local_currency = '1,256,633.43'

SELECT TOP 10 amount_in_local_currency
FROM bronze.erp_sap_je
WHERE amount_in_local_currency LIKE '%"%'

SELECT *
FROM bronze.erp_sap_je
WHERE amount_in_local_currency IS NULL

-- i. local currency
SELECT
*
FROM bronze.erp_sap_je
WHERE local_currency IS NULL

SELECT
*
FROM bronze.erp_sap_je
WHERE local_currency != 'PHP'

-- j. tax_code
SELECT 
tax_code,
COUNT(*)
FROM bronze.erp_sap_je
GROUP BY tax_code
HAVING COUNT(*) > 1 

SELECT *
FROM bronze.erp_sap_je
WHERE tax_code = 'I0'

-- k. clearing_document: distinct, count, len
SELECT DISTINCT
clearing_document
FROM bronze.erp_sap_je

SELECT
clearing_document,
COUNT(*)
FROM bronze.erp_sap_je
GROUP BY clearing_document
HAVING COUNT(*) > 1

SELECT *
FROM bronze.erp_sap_je
WHERE clearing_document IS NULL OR LEN(clearing_document) != 10

-- m. profit_center: distinct, len, count

SELECT DISTINCT
profit_center
FROM bronze.erp_sap_je

SELECT
profit_center,
COUNT(*)
FROM bronze.erp_sap_je
GROUP BY profit_center
HAVING COUNT(*) > 1

SELECT *
FROM bronze.erp_sap_je
WHERE profit_center IS NULL OR LEN(profit_center) != 3

-- n. cost_center

SELECT DISTINCT
cost_center
FROM bronze.erp_sap_je

SELECT
cost_center,
COUNT(*)
FROM bronze.erp_sap_je
GROUP BY cost_center
HAVING COUNT(*) > 1

SELECT *
FROM bronze.erp_sap_je
WHERE cost_center IS NULL OR LEN(cost_center) != 3


SELECT DISTINCT
cost_center
FROM bronze.erp_sap_je

SELECT
profit_center,
COUNT(*)
FROM bronze.erp_sap_je
GROUP BY profit_center
HAVING COUNT(*) > 1

SELECT *
FROM bronze.erp_sap_je
WHERE profit_center IS NULL OR LEN(profit_center) != 3

-- o. transaction_code: DISTINCT, COUNT, LEN, NULL

SELECT DISTINCT
transaction_code
FROM bronze.erp_sap_je

SELECT
transaction_code,
COUNT(*)
FROM bronze.erp_sap_je
GROUP BY transaction_code
HAVING COUNT(*) != 1

SELECT *
FROM bronze.erp_sap_je
WHERE profit_center IS NULL OR LEN(profit_center) != 3

