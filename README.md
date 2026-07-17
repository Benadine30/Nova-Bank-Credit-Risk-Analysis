**EXECUTIVE SUMMARY**

This project delivers an end-to-end credit risk analysis for Nova Bank using SQL Server and Power BI. The objective was to identify the key drivers of loan default, evaluate borrower risk, and provide data-driven recommendations to support better lending decisions.
The analysis was performed on 32,581 loan applications across the United States, United Kingdom, and Canada, representing over $312 million in total loan value. SQL was used for data cleaning, transformation, exploratory analysis, and business reporting, while Power BI was used to build an interactive dashboard for portfolio monitoring and risk analysis.

The results show that loan grade, debt-to-income ratio (DTI), loan-to-income ratio (LTI), prior default history, and home ownership are the strongest indicators of credit risk, whereas geography, gender, employment type, marital status, and education have little or no standalone predictive value. These insights provide a transparent framework for improving underwriting decisions and reducing portfolio risk.

**DATA OVERVIEW & METHODOLOGY**

The dataset contains 32,581 loan applications with 29 attributes, including borrower demographics, loan details, employment information, income, loan grade, repayment status, debt-to-income ratio, prior default history, and home ownership.

**The project followed an end-to-end analytics workflow:**
. Imported and cleaned the dataset using SQL Server.
. Identified and handled data quality issues, including invalid age and income records.
. Performed exploratory data analysis using SQL.
. Used joins, CASE statements, aggregate functions, Common Table Expressions (CTEs), window functions, and ranking functions to generate business insights.
. Created a rule-based risk segmentation model (Safe, Watch, and Risky) based on loan grade, DTI, and previous default history.
. Built an interactive three-page Power BI dashboard using DAX measures to visualize portfolio performance and credit risk.

The analysis focuses on understanding the current loan portfolio rather than building a predictive machine learning model.

**KEY INSIGHTS**
. The loan portfolio consists of 32,581 applications with a 21.8% default rate and 78.2% non-default rate, representing over $312 million in total loan value.
. Loan grade is the strongest predictor of default. Default rates increase significantly from Grade A (10.0%) to Grade G (98.4%), with the largest jump occurring between Grades C and D.
. Debt consolidation and medical loans recorded the highest default rates, while education and business (venture) loans performed considerably better.
. Affordability metrics, particularly debt-to-income and loan-to-income ratios, explain borrower risk better than annual income alone.
. Home ownership is a strong indicator of repayment behaviour. Renters default at approximately four times the rate of borrowers who own their homes outright.
. Geography, gender, marital status, employment type, and education showed little or no meaningful relationship with default risk, suggesting these variables should not be primary underwriting factors.
. The custom Risk Segmentation Model effectively separates borrowers into Safe, Watch, and Risky groups, with the Risky segment defaulting at over twelve times the rate of the Safe segment despite representing less than 5% of applicants.

**RECOMMENDATIONS**
. Strengthen underwriting for Grades D through G, particularly Grades F and G, by introducing stricter approval criteria or mandatory manual reviews.
. Use debt-to-income and loan-to-income ratios alongside loan grades during credit assessment to better identify borrowers with affordability risks.
. Prioritize applicants with multiple risk indicators, such as high DTI, high LTI, and previous defaults, for manual review before loan approval.
. Increase monitoring of debt consolidation and medical loans, as these loan purposes consistently demonstrate higher default risk.
. Use home ownership status as an additional risk assessment factor, since renters exhibit substantially higher default rates than homeowners.
. Avoid using geography, gender, marital status, education, or employment type as approval or pricing factors because the analysis found no meaningful evidence that they independently predict loan default.
. Continue monitoring portfolio performance through interactive dashboards to identify changes in borrower risk and support evidence-based lending decisions.



