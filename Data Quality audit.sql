/* ------------------------------
          DATA QUALITY AUDIT 
   -------------------------------- */

-- Flaging implausible values (ages that don't exist / income outliers)*/ 
SELECT
    client_ID, person_age, person_income, person_emp_length,
    CASE
        WHEN person_age > 90 THEN 'Implausible age'
        WHEN person_income > 500000 THEN 'Extreme income outlier'
        WHEN person_emp_length > (person_age - 16) THEN 'Emp length exceeds working-age years'
        ELSE 'OK'
    END AS data_quality_flag
FROM dbo.Novabank_Credit_Risk_data
WHERE person_age > 90
   OR person_income > 500000
   OR person_emp_length > (person_age - 16)
ORDER BY person_age DESC;


-- Audit NULLs / missing values in the two fields that have gaps
--      (loan_int_rate, person_emp_length), and check for duplicate client IDs.
SELECT
    SUM(CASE WHEN loan_int_rate IS NULL THEN 1 ELSE 0 END)      AS missing_interest_rate,
    SUM(CASE WHEN person_emp_length IS NULL THEN 1 ELSE 0 END)  AS missing_emp_length,
    COUNT(*) - COUNT(DISTINCT client_ID)                        AS duplicate_client_ids
FROM dbo.Novabank_Credit_Risk_data;

