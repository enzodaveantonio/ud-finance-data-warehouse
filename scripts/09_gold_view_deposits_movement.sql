CREATE VIEW gold.fact_deposits_movement AS

SELECT
	posting_date,
	transaction_code	AS	sap_transaction_code,
	account				AS	sap_account_num,
	amount_dr			AS	sap_amount_dr,
	amount_cr			AS	sap_amount_cr,
	is_deposit_reversal	AS	sap_deposit_reversal,
	NULL				AS	tm_transaction_code,
	NULL				AS	tm_amount_dr,
	NULL				AS	tm_amount_cr,
	NULL				AS	tm_reversal_flag,
	'SAP'				AS	source_system
 
FROM silver.erp_sap_je
WHERE transaction_code LIKE 'IPTKOTCR%' OR transaction_code LIKE 'IPTKOTDR%' OR transaction_code LIKE 'ITMDIPCD%'
        OR transaction_code LIKE 'ITMDIPCR%' OR transaction_code LIKE 'ITMDIPDR%' OR transaction_code LIKE 'RPTKBPDR%' OR
        transaction_code LIKE 'RPTKCICR%' OR transaction_code LIKE 'RPTKCODR%' OR transaction_code LIKE 'RPTKRMCR%' OR
        transaction_code LIKE 'RPTKSMDR%' OR transaction_code LIKE 'RTMDACCD%' OR transaction_code LIKE 'RTMDACDR%' OR
        transaction_code LIKE 'RTMDETCD%' OR transaction_code LIKE 'RTMDETCR%' OR transaction_code LIKE 'RTMDETDR%' OR
        transaction_code LIKE 'RTMDMDDR%' OR transaction_code LIKE 'RTMDOPCR%' OR transaction_code LIKE 'RTMDOPDR%' OR
        transaction_code LIKE 'RVDCOPDR%'
ORDER BY posting_date

UNION ALL

SELECT 
	transaction_posting_date	AS	posting_date,
	NULL					AS	sap_transaction_code,
	NULL					AS	sap_account_num,
	NULL					AS	sap_amount_dr,
	NULL					AS	sap_amount_cr,
	NULL					AS	sap_deposit_reversal,
	transaction_type_code	AS	tm_transaction_code,
	tm_amount_dr			AS	tm_amount_dr,
	tm_amount_cr			AS	tm_amount_cr,
	transaction_reversal_flag	AS	tm_reversal_flag,
	'TM'					AS	source_system

FROM silver.core_tm_sl_aggregates
