# Nova-Bank-Credit-Risk-Analysis
This is an end-to-end credit risk analytics project on a 32,581-row dataset of borrowers across the USA, UK and Canada, combining T-SQL analysis, and an interactive Power BI dashboard

**Data Overview & Methodology**
The dataset is a point-in-time snapshot with no date field, so default rates throughout this report describe the existing book, not a forward-looking probability-of-default model. Analysis was performed in two layers: T-SQL queries against MS SQL Server for structured deep-dive analysis (portfolio summary, cohort segmentation, window-function quartile/decile analysis, data quality auditing, and a lending-policy simulation), and a 3-page Power BI report built on 26+ DAX measures for interactive review.
Risk segments (Safe / Watch / Risky) are a transparent, rule-based classification — not a machine-learning model — defined as: Safe = Grade A/B, DTI < 35%, no prior default on file; Risky = Grade F/G, or DTI ≥ 60%; Watch = everything else. This keeps the segmentation auditable and explainable to underwriting staff, at the cost of being a starting point rather than a fully tuned scorecard.
<img width="468" height="206" alt="image" src="https://github.com/user-attachments/assets/c7500737-53ef-4e14-aa58-578d2f0297f8" />

**Executive Summary**
Nova Bank's portfolio of 32,581 loan applications across the USA, UK, and Canada carries an overall default rate of 21.8% (78.2% non-default rate) on $312.4M of total loan value, of which $77.1M (24.7%) sits in loans that ultimately defaulted. This report is built directly from, and validated against, the 3-page Power BI Report 
The core finding, confirmed across every page of the dashboard, is that repayment behaviour is driven by a small set of underwriting variables — loan grade, debt-to-income ratio, loan-to-income ratio, and prior default history — while location, gender, employment type, and marital status carry little to no standalone predictive value. This is a reassuring fair-lending signal, but it also means the bank's existing grade and affordability data already contains most of the risk signal it needs; no new data collection is required to act on these findings.
Three findings carry the most weight for underwriting policy:
•	Risk segment, not geography or demographics, explains default. The Risky segment (4.9% of the book, 1,591 applicants) defaults at 72.5% — more than 12x the Safe segment's 5.9%.
•	Default rate is flat within a 20.9%–22.5% band across every state and province, and within 1.5 points across every home-loan-purpose category — geography and (individually) employment type are not risk drivers.
•	Home ownership is the one demographic-adjacent field that does move the needle: renters default at 31.6% versus 7.5% for outright homeowners, a 4x spread almost certainly reflecting equity cushion rather than tenure itself.
A data quality issue was identified and corrected during analysis: 58 records (0.18%) carried implausible ages (up to 144 years) or incomes (up to $6M). These were excluded from distributional charts (e.g. the income-vs-default scatter) but retained in portfolio totals, since their share is negligible; they are flagged here for the record.



