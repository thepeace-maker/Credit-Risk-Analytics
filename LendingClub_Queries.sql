SELECT COUNT(*) AS n FROM dbo.loans_raw;

SELECT loan_status, COUNT(*) AS loans
FROM dbo.loans_raw GROUP BY loan_status ORDER BY loans DESC;

CREATE OR ALTER VIEW dbo.loans AS
SELECT id,
       loan_amnt, funded_amnt, installment, annual_inc, dti,
       TRY_CAST(LEFT(LTRIM(term), 2) AS INT)                  AS term_months,
       TRY_CAST(REPLACE(int_rate, '%', '') AS FLOAT)           AS int_rate_pct,
       TRY_CAST(REPLACE(revol_util, '%', '') AS FLOAT)         AS revol_util_pct,
       grade, sub_grade, LTRIM(RTRIM(emp_length)) AS emp_length,
       home_ownership, verification_status, purpose, addr_state,
       2000 + TRY_CAST(RIGHT(RTRIM(issue_d), 2) AS INT)        AS issue_year,
       loan_status,
       CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END AS is_charged_off,
       total_pymnt, total_rec_prncp, total_rec_int, recoveries,
       ROUND(100.0 * (total_pymnt - funded_amnt) / NULLIF(funded_amnt, 0), 1) AS net_return_pct
FROM dbo.loans_raw
WHERE loan_status IN ('Fully Paid', 'Charged Off');

SELECT COUNT(*) AS completed_loans,
       SUM(is_charged_off) AS charged_off,
       ROUND(100.0 * AVG(CAST(is_charged_off AS FLOAT)), 1) AS charge_off_pct,
       MIN(issue_year) AS first_year, MAX(issue_year) AS last_year,
       ROUND(AVG(int_rate_pct), 1) AS avg_rate
FROM dbo.loans;

-- B01: Charge-off rate, interest rate and return by grade
SELECT grade,
       COUNT(*) AS loans,
       SUM(is_charged_off) AS charged_off,
       ROUND(100.0 * AVG(CAST(is_charged_off AS FLOAT)), 1) AS charge_off_pct,
       ROUND(AVG(int_rate_pct), 1) AS avg_int_rate,
       ROUND(100.0 * (SUM(total_pymnt) - SUM(funded_amnt)) / SUM(funded_amnt), 1) AS net_return_pct
FROM dbo.loans
GROUP BY grade
ORDER BY grade;

-- B02: Same view by term
SELECT term_months,
       COUNT(*) AS loans,
       ROUND(100.0 * AVG(CAST(is_charged_off AS FLOAT)), 1) AS charge_off_pct,
       ROUND(AVG(int_rate_pct), 1) AS avg_int_rate,
       ROUND(100.0 * (SUM(total_pymnt) - SUM(funded_amnt)) / SUM(funded_amnt), 1) AS net_return_pct
FROM dbo.loans
GROUP BY term_months
ORDER BY term_months;

-- B03: Riskiest purposes (at least 200 loans)
SELECT purpose,
       COUNT(*) AS loans,
       ROUND(100.0 * AVG(CAST(is_charged_off AS FLOAT)), 1) AS charge_off_pct,
       ROUND(AVG(int_rate_pct), 1) AS avg_int_rate,
       ROUND(100.0 * (SUM(total_pymnt) - SUM(funded_amnt)) / SUM(funded_amnt), 1) AS net_return_pct
FROM dbo.loans
GROUP BY purpose
HAVING COUNT(*) >= 200
ORDER BY charge_off_pct DESC;

-- B04: Is small business riskier than other loans of the SAME grade?
SELECT grade,
       CASE WHEN purpose = 'small_business' THEN 'Small business' ELSE 'All other purposes' END AS segment,
       COUNT(*) AS loans,
       ROUND(100.0 * AVG(CAST(is_charged_off AS FLOAT)), 1) AS charge_off_pct,
       ROUND(AVG(int_rate_pct), 1) AS avg_int_rate,
       ROUND(100.0 * (SUM(total_pymnt) - SUM(funded_amnt)) / SUM(funded_amnt), 1) AS net_return_pct
FROM dbo.loans
GROUP BY grade, CASE WHEN purpose = 'small_business' THEN 'Small business' ELSE 'All other purposes' END
ORDER BY grade, segment;

-- B05: Debt-to-income bands
SELECT CASE WHEN dti < 10 THEN '1: under 10'
            WHEN dti < 15 THEN '2: 10 to 14.9'
            WHEN dti < 20 THEN '3: 15 to 19.9'
            WHEN dti < 25 THEN '4: 20 to 24.9'
            ELSE '5: 25 and over' END AS dti_band,
       COUNT(*) AS loans,
       ROUND(100.0 * AVG(CAST(is_charged_off AS FLOAT)), 1) AS charge_off_pct,
       ROUND(AVG(int_rate_pct), 1) AS avg_int_rate,
       ROUND(100.0 * (SUM(total_pymnt) - SUM(funded_amnt)) / SUM(funded_amnt), 1) AS net_return_pct
FROM dbo.loans
WHERE dti IS NOT NULL
GROUP BY CASE WHEN dti < 10 THEN '1: under 10'
              WHEN dti < 15 THEN '2: 10 to 14.9'
              WHEN dti < 20 THEN '3: 15 to 19.9'
              WHEN dti < 25 THEN '4: 20 to 24.9'
              ELSE '5: 25 and over' END
ORDER BY dti_band;

-- B06: By issue year
SELECT issue_year,
       COUNT(*) AS loans,
       ROUND(100.0 * AVG(CAST(is_charged_off AS FLOAT)), 1) AS charge_off_pct,
       ROUND(AVG(int_rate_pct), 1) AS avg_int_rate,
       ROUND(100.0 * (SUM(total_pymnt) - SUM(funded_amnt)) / SUM(funded_amnt), 1) AS net_return_pct
FROM dbo.loans
GROUP BY issue_year
ORDER BY issue_year;

-- B07: What small-business loans earned, in money
SELECT CASE WHEN purpose = 'small_business' THEN 'Small business' ELSE 'All other purposes' END AS segment,
       CASE WHEN grade = 'A' THEN 'Grade A' ELSE 'Grades B to G' END AS grade_group,
       COUNT(*) AS loans,
       ROUND(SUM(funded_amnt), 0) AS lent,
       ROUND(SUM(total_pymnt), 0) AS repaid,
       ROUND(SUM(total_pymnt) - SUM(funded_amnt), 0) AS net_profit,
       ROUND(100.0 * (SUM(total_pymnt) - SUM(funded_amnt)) / SUM(funded_amnt), 1) AS net_return_pct
FROM dbo.loans
GROUP BY CASE WHEN purpose = 'small_business' THEN 'Small business' ELSE 'All other purposes' END,
         CASE WHEN grade = 'A' THEN 'Grade A' ELSE 'Grades B to G' END
ORDER BY segment, grade_group;

