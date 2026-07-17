/* ============================================================================
   NOVA BANK — CREDIT RISK ANALYTICS
   
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


-- Q1. What does the overall loan portfolio look like (volume, value, default rate)*/
SELECT
    COUNT(*) AS total_applications,
    SUM(CAST(loan_status AS INT)) AS total_defaults,
    CAST(SUM(CAST(loan_status AS FLOAT)) * 100.0 / COUNT(*) AS DECIMAL(5,2))  AS default_rate,
    SUM(loan_amnt) AS total_loan_value,
    SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END) AS loan_value_at_risk,
    AVG(loan_int_rate) AS avg_interest_rate
FROM dbo.Novabank_Credit_Risk_data;


-- Q2. How does default rate vary by loan grade (A–G)?
SELECT
    loan_grade,
    COUNT(*) AS applications,
    SUM(CAST(loan_status AS INT)) AS defaults,
    CAST(AVG(CAST(loan_status AS FLOAT)) * 100.0 AS DECIMAL(5,2)) AS default_rate,
    ROUND(AVG(loan_int_rate),2) AS avg_interest_rate
FROM dbo.Novabank_Credit_Risk_data
GROUP BY loan_grade
ORDER BY loan_grade;


-- Q3. Do certain loan purposes (loan_intent) carry more risk than others?
SELECT
    loan_intent,
    COUNT(*) AS applications,
    CAST(AVG(CAST(loan_status AS FLOAT)) AS DECIMAL(5,4))  AS default_rate,
    ROUND(AVG(loan_amnt),2) AS avg_loan_amnt,
    ROUND(AVG(loan_percent_income),4) AS avg_loan_pct_income
FROM dbo.Novabank_Credit_Risk_data 
GROUP BY loan_intent
ORDER BY default_rate DESC;


-- Q5. Does home ownership status change the likelihood of default?
SELECT
    person_home_ownership,
    COUNT(*) AS applications,
    CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2))   AS default_rate
FROM dbo.Novabank_Credit_Risk_data
GROUP BY person_home_ownership
ORDER BY default_rate DESC;


-- Q6. Does employment type (full-time/part-time/self-employed/unemployed) matter?
SELECT
    employment_type,
    COUNT(*)  AS applications,
    CAST(AVG(CAST(loan_status AS FLOAT)) AS DECIMAL(5,4))   AS default_rate,
    ROUND(AVG(person_income),2) AS avg_income
FROM dbo.Novabank_Credit_Risk_data
GROUP BY employment_type
ORDER BY default_rate DESC;


-- Q7. Do demographic factors (marital status, education level) show a fair-lending
--     red flag, i.e. meaningfully different default rates?

SELECT marital_status, NULL AS education_level,
       COUNT(*) AS applications, CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2)) AS default_rate
FROM dbo.Novabank_Credit_Risk_data GROUP BY marital_status
UNION ALL
SELECT NULL, education_level,
       COUNT(*), CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2))
FROM dbo.Novabank_Credit_Risk_data GROUP BY education_level
ORDER BY default_rate DESC;


/* ----------------------------------------------------------------------------
   SECTION B — CREDIT HISTORY & PRIOR BEHAVIOUR
   ---------------------------------------------------------------------------- */

-- Q8. How much riskier are applicants with a prior default on file, and by what
--     multiple compared to those without one?

WITH by_flag AS (
    SELECT
        cb_person_default_on_file,
        CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2)) AS default_rate
    FROM dbo.Novabank_Credit_Risk_data
    GROUP BY cb_person_default_on_file
)
SELECT
    MAX(CASE WHEN cb_person_default_on_file = 'Y' THEN default_rate END) AS prior_defaulter_rate,
    MAX(CASE WHEN cb_person_default_on_file = 'N' THEN default_rate END) AS no_prior_default_rate,
    CAST(MAX(CASE WHEN cb_person_default_on_file = 'Y' THEN default_rate END) /
         NULLIF(MAX(CASE WHEN cb_person_default_on_file = 'N' THEN default_rate END),0) AS DECIMAL(5,2)) AS risk_multiplier
FROM by_flag;


-- Q9. Does a longer credit history reduce default risk?
SELECT
    CASE
        WHEN cb_person_cred_hist_length <= 2  THEN '0-2 yrs'
        WHEN cb_person_cred_hist_length <= 5  THEN '3-5 yrs'
        WHEN cb_person_cred_hist_length <= 10 THEN '6-10 yrs'
        ELSE '10+ yrs'
    END AS credit_history_bracket,
    COUNT(*) AS applications,
    CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2))   AS default_rate
FROM dbo.Novabank_Credit_Risk_data
GROUP BY
    CASE
        WHEN cb_person_cred_hist_length <= 2  THEN '0-2 yrs'
        WHEN cb_person_cred_hist_length <= 5  THEN '3-5 yrs'
        WHEN cb_person_cred_hist_length <= 10 THEN '6-10 yrs'
        ELSE '10+ yrs'
    END
ORDER BY MIN(cb_person_cred_hist_length);


-- Q10. Does employment length reduce default risk?
SELECT
    CASE
        WHEN person_emp_length < 2  THEN '<2 yrs'
        WHEN person_emp_length < 5  THEN '2-4 yrs'
        WHEN person_emp_length < 10 THEN '5-9 yrs'
        ELSE '10+ yrs'
    END AS emp_length_bracket,
    COUNT(*) AS applications,
    CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2))   AS default_rate
FROM dbo.Novabank_Credit_Risk_data
WHERE person_emp_length IS NOT NULL
GROUP BY
    CASE
        WHEN person_emp_length < 2  THEN '<2 yrs'
        WHEN person_emp_length < 5  THEN '2-4 yrs'
        WHEN person_emp_length < 10 THEN '5-9 yrs'
        ELSE '10+ yrs'
    END
ORDER BY MIN(person_emp_length);


-- Q11. Do past delinquencies predict default?

SELECT
    past_delinquencies,
    COUNT(*)                                              AS applications,
    CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2))   AS default_rate
FROM dbo.Novabank_Credit_Risk_data
GROUP BY past_delinquencies
ORDER BY past_delinquencies;


-- Q12. Does the number of open credit accounts relate to default?
SELECT
    CASE
        WHEN open_accounts <= 3  THEN '0-3'
        WHEN open_accounts <= 7  THEN '4-7'
        WHEN open_accounts <= 11 THEN '8-11'
        ELSE '12+'
    END AS open_accounts_bracket,
    COUNT(*)                                              AS applications,
    CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2))   AS default_rate
FROM dbo.Novabank_Credit_Risk_data
GROUP BY
    CASE
        WHEN open_accounts <= 3  THEN '0-3'
        WHEN open_accounts <= 7  THEN '4-7'
        WHEN open_accounts <= 11 THEN '8-11'
        ELSE '12+'
    END
ORDER BY MIN(open_accounts);


-- Q13. Does credit utilization ratio relate to default?
SELECT
    CASE
        WHEN credit_utilization_ratio < 0.25 THEN '0-25%'
        WHEN credit_utilization_ratio < 0.50 THEN '25-50%'
        WHEN credit_utilization_ratio < 0.75 THEN '50-75%'
        ELSE '75-100%'
    END AS utilization_bracket,
    COUNT(*)                                              AS applications,
    CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2))   AS default_rate
FROM dbo.Novabank_Credit_Risk_data
GROUP BY
    CASE
        WHEN credit_utilization_ratio < 0.25 THEN '0-25%'
        WHEN credit_utilization_ratio < 0.50 THEN '25-50%'
        WHEN credit_utilization_ratio < 0.75 THEN '50-75%'
        ELSE '75-100%'
    END
ORDER BY MIN(credit_utilization_ratio);


/* ----------------------------------------------------------------------------
   SECTION C — AFFORDABILITY: LOAN-TO-INCOME / DEBT-TO-INCOME
   ---------------------------------------------------------------------------- */

-- Q14. How does debt-to-income ratio relate to repayment outcome? 
SELECT
    CASE
        WHEN debt_to_income_ratio < 0.20 THEN '<20%'
        WHEN debt_to_income_ratio < 0.35 THEN '20-35%'
        WHEN debt_to_income_ratio < 0.50 THEN '35-50%'
        WHEN debt_to_income_ratio < 0.65 THEN '50-65%'
        ELSE '65%+'
    END AS dti_bracket,
    COUNT(*)                                              AS applications,
    CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2))   AS default_rate
FROM dbo.Novabank_Credit_Risk_data
GROUP BY
    CASE
        WHEN debt_to_income_ratio < 0.20 THEN '<20%'
        WHEN debt_to_income_ratio < 0.35 THEN '20-35%'
        WHEN debt_to_income_ratio < 0.50 THEN '35-50%'
        WHEN debt_to_income_ratio < 0.65 THEN '50-65%'
        ELSE '65%+'
    END
ORDER BY MIN(debt_to_income_ratio);


-- Q15. How does loan-to-income ratio relate to default?
SELECT
    CASE
        WHEN loan_to_income_ratio < 0.10 THEN '<10%'
        WHEN loan_to_income_ratio < 0.20 THEN '10-20%'
        WHEN loan_to_income_ratio < 0.35 THEN '20-35%'
        ELSE '35%+'
    END AS lti_bracket,
    COUNT(*)                                              AS applications,
    CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2))   AS default_rate
FROM dbo.Novabank_Credit_Risk_data
GROUP BY
    CASE
        WHEN loan_to_income_ratio < 0.10 THEN '<10%'
        WHEN loan_to_income_ratio < 0.20 THEN '10-20%'
        WHEN loan_to_income_ratio < 0.35 THEN '20-35%'
        ELSE '35%+'
    END
ORDER BY MIN(loan_to_income_ratio);


-- Q16. How does loan_percent_income (share of income eaten by this loan's
--      repayment) relate to default?
SELECT
    CASE
        WHEN loan_percent_income < 0.10 THEN '<10%'
        WHEN loan_percent_income < 0.20 THEN '10-20%'
        WHEN loan_percent_income < 0.35 THEN '20-35%'
        ELSE '35%+'
    END AS pct_income_bracket,
    COUNT(*)                                              AS applications,
    CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2))   AS default_rate
FROM dbo.Novabank_Credit_Risk_data
GROUP BY
    CASE
        WHEN loan_percent_income < 0.10 THEN '<10%'
        WHEN loan_percent_income < 0.20 THEN '10-20%'
        WHEN loan_percent_income < 0.35 THEN '20-35%'
        ELSE '35%+'
    END
ORDER BY MIN(loan_percent_income);


-- Q17. Side-by-side profile of defaulters vs. non-defaulters across every key
--      affordability metric.
SELECT
    loan_status,
    COUNT(*)                       AS applications,
    AVG(person_income)             AS avg_income,
    AVG(loan_amnt)                 AS avg_loan_amnt,
    AVG(loan_int_rate)             AS avg_interest_rate,
    AVG(loan_percent_income)       AS avg_loan_pct_income,
    AVG(loan_to_income_ratio)      AS avg_loan_to_income,
    AVG(debt_to_income_ratio)      AS avg_debt_to_income,
    AVG(other_debt)                AS avg_other_debt
FROM dbo.Novabank_Credit_Risk_data
GROUP BY loan_status;


-- Q18. Average income of defaulters vs. non-defaulters, broken out by country.
SELECT
    country,
    loan_status,
    COUNT(*)             AS applications,
    ROUND(AVG(person_income),2)   AS avg_income
FROM dbo.Novabank_Credit_Risk_data
GROUP BY country, loan_status
ORDER BY country, loan_status;


/* ----------------------------------------------------------------------------
   SECTION D — LOAN STRUCTURE
   ---------------------------------------------------------------------------- */

-- Q19. Which loan terms (12/24/36/60 months) carry more risk?

SELECT
    loan_term_months,
    COUNT(*) AS applications,
    CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2))   AS default_rate,
    ROUND(AVG(loan_amnt),2) AS avg_loan_amnt
FROM dbo.Novabank_Credit_Risk_data
GROUP BY loan_term_months
ORDER BY loan_term_months;


-- Q20. What is the average interest rate and loan amount charged per grade,
--      and does pricing (interest rate) actually compensate for the extra risk?
SELECT
    loan_grade,
    COUNT(*) AS applications,
    AVG(loan_int_rate) AS avg_interest_rate,
    AVG(loan_amnt) AS avg_loan_amnt,
    CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2))   AS default_rate,
    CAST(AVG(loan_int_rate) / NULLIF(AVG(CAST(loan_status AS FLOAT)),0) AS DECIMAL(10,2)) AS rate_per_unit_risk
FROM dbo.Novabank_Credit_Risk_data
GROUP BY loan_grade
ORDER BY loan_grade;


/* ----------------------------------------------------------------------------
   SECTION E — DEEPER SEGMENTATION
   ---------------------------------------------------------------------------- */

-- Q21. Split the portfolio into DTI quartiles using NTILE and calculate the
--      default rate for each quartile

WITH quartiled AS (
    SELECT
        loan_status,
        debt_to_income_ratio,
        NTILE(4) OVER (ORDER BY debt_to_income_ratio) AS dti_quartile
    FROM dbo.Novabank_Credit_Risk_data
)
SELECT
    dti_quartile,
    COUNT(*) AS applications,
    MIN(debt_to_income_ratio) AS min_dti,
    MAX(debt_to_income_ratio) AS max_dti,
    CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2)) AS default_rate
FROM quartiled
GROUP BY dti_quartile
ORDER BY dti_quartile;


-- Q22. Within each loan grade, rank applicants by loan amount to find the
--      largest exposures per risk tier (RANK window function).
SELECT *
FROM (
    SELECT
        client_ID, loan_grade, loan_amnt, loan_status,
        RANK() OVER (PARTITION BY loan_grade ORDER BY loan_amnt DESC) AS amt_rank_in_grade
    FROM dbo.Novabank_Credit_Risk_data
) ranked
WHERE amt_rank_in_grade <= 5
ORDER BY loan_grade, amt_rank_in_grade;


-- Q23. Build a cumulative view of default rate as loan amount deciles increase
 — do bigger loans skew riskier?

WITH deciled AS (
    SELECT
        loan_status, loan_amnt,
        NTILE(10) OVER (ORDER BY loan_amnt) AS amt_decile
    FROM dbo.Novabank_Credit_Risk_data
)
SELECT
    amt_decile,
    COUNT(*)                                              AS applications,
    MIN(loan_amnt)                                         AS min_amt,
    MAX(loan_amnt)                                         AS max_amt,
    CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2))   AS decile_default_rate,
    CAST(AVG(AVG(CAST(loan_status AS FLOAT))) OVER (ORDER BY amt_decile
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) *100.0 AS DECIMAL(5,2)) AS running_avg_default_rate
FROM deciled
GROUP BY amt_decile
ORDER BY amt_decile;


-- Q24. Build a simple, explainable "safe vs. risky" segmentation and measure
--      each segment's size and default rate 

WITH segmented AS (
    SELECT
        *,
        CASE
            WHEN loan_grade IN ('A','B')
                 AND debt_to_income_ratio < 0.35
                 AND cb_person_default_on_file = 'N'  THEN 'Safe'
            WHEN loan_grade IN ('F','G')
                 OR debt_to_income_ratio >= 0.60
                 OR (cb_person_default_on_file = 'Y' AND loan_grade IN ('D','E','F','G')) THEN 'Risky'
            ELSE 'Watch'
        END AS risk_segment
    FROM dbo.Novabank_Credit_Risk_data
)
SELECT
    risk_segment,
    COUNT(*)  AS applications,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS pct_of_portfolio,
    CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2)) AS default_rate,
    SUM(loan_amnt) AS total_loan_value
FROM segmented
GROUP BY risk_segment
ORDER BY default_rate DESC;


-- Q25. Compound-risk cohort: applicants who are simultaneously high-DTI,
--      high loan-to-income, AND carry a prior default — how much worse are they
--      than the portfolio baseline?
WITH baseline AS (
    SELECT CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2)) AS portfolio_default_rate
    FROM dbo.Novabank_Credit_Risk_data
)
SELECT
    'Compound high-risk cohort' AS cohort,
    COUNT(*) AS applications,
    CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2))   AS cohort_default_rate,
    (SELECT portfolio_default_rate FROM baseline) AS portfolio_default_rate,
    CAST(AVG(CAST(loan_status AS FLOAT)) / (SELECT portfolio_default_rate FROM baseline) AS DECIMAL(5,2)) AS risk_multiplier
FROM dbo.Novabank_Credit_Risk_data
WHERE debt_to_income_ratio >= 0.50
  AND loan_to_income_ratio >= 0.20
  AND cb_person_default_on_file = 'Y';


-- Q26. Self-employed applicants with high DTI — a common underwriting blind
--      spot (income variability + heavy debt load).
SELECT
    employment_type,
    CASE WHEN debt_to_income_ratio >= 0.50 THEN 'High DTI (50%+)' ELSE 'Lower DTI' END AS dti_flag,
    COUNT(*) AS applications,
    CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2)) AS default_rate
FROM dbo.Novabank_Credit_Risk_data
WHERE employment_type = 'Self-employed'
GROUP BY employment_type,
    CASE WHEN debt_to_income_ratio >= 0.50 THEN 'High DTI (50%+)' ELSE 'Lower DTI' END;


-- Q27. Which city/state combinations show the highest default rates?
SELECT TOP 10
    state, city,
    COUNT(*) AS applications,
    CAST(AVG(CAST(loan_status AS FLOAT)) *100.0 AS DECIMAL(5,2))   AS default_rate
FROM dbo.Novabank_Credit_Risk_data
GROUP BY state, city
HAVING COUNT(*) >= 200
ORDER BY default_rate DESC;


/* ----------------------------------------------------------------------------
   SECTION F — POLICY SIMULATION (turns analysis into a lending decision)
   ---------------------------------------------------------------------------- */

-- Q28. If Nova Bank tightened policy to decline all loan_grade F & G applicants,
--      how many defaults would be avoided vs. how many good (non-defaulting)
--      customers would be turned away? (cost/benefit of a stricter cut-off)
SELECT
    CASE WHEN loan_grade IN ('F','G') THEN 'Would be declined (F/G)' ELSE 'Still approved (A-E)' END AS policy_bucket,
    COUNT(*)                                                          AS applications,
    SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END)                  AS defaults_in_bucket,
    SUM(CASE WHEN loan_status = 0 THEN 1 ELSE 0 END)                  AS good_customers_in_bucket,
    SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)          AS defaulted_value_in_bucket,
    SUM(loan_amnt)                                                    AS total_value_in_bucket
FROM dbo.Novabank_Credit_Risk_data
GROUP BY CASE WHEN loan_grade IN ('F','G') THEN 'Would be declined (F/G)' ELSE 'Still approved (A-E)' END;

