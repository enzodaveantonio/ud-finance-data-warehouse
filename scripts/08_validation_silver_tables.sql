



-- a. cleared_open_items_symbol: check values, check for NULLS, DISTINCT
SELECT DISTINCT
	cleared_open_items_symbol

FROM silver.erp_sap_je


SELECT
*
FROM silver.erp_sap_je
WHERE cleared_open_items_symbol = '@01\QPosted@'

-- b. company_code: Check for distinct values and NULLS
SELECT
*
FROM silver.erp_sap_je
WHERE company_code IS NULL

-- c. account: check groupings, distincts, count for each

SELECT
*
FROM silver.erp_sap_je
WHERE account IS NULL OR LEN(account) != 7

SELECT
account,
COUNT(*)
FROM silver.erp_sap_je
GROUP BY account
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC

-- d. document_number: Check count, nulls, same values of the same doc number

SELECT
document_number,
COUNT(*)
FROM silver.erp_sap_je
GROUP BY document_number
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC

SELECT
*
FROM silver.erp_sap_je
WHERE document_number IS NULL

SELECT
*
FROM silver.erp_sap_je
WHERE document_number = '2300007581'

-- e. document type: distinct, count, nulls

SELECT DISTINCT
document_type
FROM silver.erp_sap_je

SELECT
*
FROM silver.erp_sap_je
WHERE document_type IS NULL

SELECT
document_type,
COUNT(*)
FROM silver.erp_sap_je
GROUP BY document_type
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC

SELECT
*
FROM silver.erp_sap_je
WHERE document_type IS NULL

-- f. document_date: date more than present, null
SELECT
*
FROM silver.erp_sap_je
WHERE document_date < '2020-01-01'

SELECT
*
FROM silver.erp_sap_je
WHERE document_date > GETDATE()

SELECT *
FROM silver.erp_sap_je
WHERE posting_date IS NULL

-- f2
SELECT DISTINCT
document_type,
document_type_description
FROM silver.erp_sap_je

--g. reference_key_3: distinct, count, len | NEED TO CLARIFY ref key purpose

SELECT reference_key_3,
COUNT(*) 
FROM silver.erp_sap_je
GROUP BY reference_key_3
HAVING COUNT(*) > 1


SELECT
*
FROM silver.erp_sap_je
WHERE LEN(reference_key_3) != 16 OR reference_key_3 IS NULL

SELECT TOP 100 *
FROM silver.erp_sap_je
WHERE LEN(reference_key_3) != 16 -- FLAG!

-- h. amount_in_local_currency
SELECT
*
FROM silver.erp_sap_je
WHERE amount_in_local_currency = '1,256,633.43'

SELECT TOP 10 amount_in_local_currency
FROM silver.erp_sap_je
WHERE amount_in_local_currency LIKE '%"%'

SELECT *
FROM silver.erp_sap_je
WHERE amount_in_local_currency IS NULL

-- i. local currency
SELECT
*
FROM silver.erp_sap_je
WHERE local_currency IS NULL

SELECT
*
FROM silver.erp_sap_je
WHERE local_currency != 'PHP'

-- j. tax_code -- FLAG
SELECT 
tax_code,
COUNT(*)
FROM silver.erp_sap_je
GROUP BY tax_code
HAVING COUNT(*) > 1 

SELECT *
FROM silver.erp_sap_je
WHERE tax_code = 'I0'

-- k. clearing_document: distinct, count, len | CLARIFY for what?
SELECT DISTINCT
clearing_document
FROM silver.erp_sap_je

SELECT
clearing_document,
COUNT(*)
FROM silver.erp_sap_je
GROUP BY clearing_document
HAVING COUNT(*) > 1

SELECT *
FROM silver.erp_sap_je
WHERE clearing_document IS NULL OR LEN(clearing_document) != 10

-- m. profit_center: distinct, len, count

SELECT DISTINCT
profit_center
FROM silver.erp_sap_je

SELECT
profit_center,
COUNT(*)
FROM silver.erp_sap_je
GROUP BY profit_center
HAVING COUNT(*) > 1

SELECT *
FROM silver.erp_sap_je
WHERE profit_center IS NULL AND LEN(profit_center) != 3

-- n. cost_center

SELECT DISTINCT
cost_center
FROM silver.erp_sap_je

SELECT
cost_center,
COUNT(*)
FROM silver.erp_sap_je
GROUP BY cost_center
HAVING COUNT(*) > 1

SELECT *
FROM silver.erp_sap_je
WHERE cost_center IS NULL OR LEN(cost_center) != 3


-- o. transaction_code: DISTINCT, COUNT, LEN, NULL

SELECT DISTINCT
transaction_code
FROM silver.erp_sap_je

SELECT
transaction_code,
COUNT(*)
FROM silver.erp_sap_je
GROUP BY transaction_code
HAVING COUNT(*) != 1
