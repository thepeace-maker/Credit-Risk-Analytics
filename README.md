# Lending Club Credit Risk: Where a P2P Lender Lost Money 💳

## 1. Problem

Lending Club is a peer-to-peer lender. Like any lender, its biggest losses come from borrowers who don't repay. **The question for management:** which loans are charged off most often, and does the interest rate charged cover the losses? Where pricing doesn't cover the risk, where should the lender tighten approval or reprice?

[Overview page]<img width="874" height="492" alt="Screenshot 2026-10-19 000841" src="https://github.com/user-attachments/assets/3e21c670-35cf-4fbc-82d7-a2cf231f034e" />

[Insights page]<img width="876" height="491" alt="Screenshot 2026-10-19 000914" src="https://github.com/user-attachments/assets/6c85df86-1485-42b8-a888-ccdea4729a32" />


## 2. Analysis

- **Data:** Lending Club loan data for loans issued 2007 to 2011 (Kaggle, file `loan.csv`): 39,717 loans, 111 columns.
- **Scope:** completed loans only (Fully Paid or Charged Off): **38,577 loans**, of which **5,627 (14.6%) were charged off**. The other 1,140 loans had different statuses (for example still being repaid) and were excluded, because their outcome isn't known.
- **Definition of bad outcome:** Charged Off, meaning no reasonable expectation of further payment.
- **Return measure:** net return = (total repaid - amount lent) / amount lent. It is a rough return, not adjusted for timing or fees.
- **Tools:** SQL Server (SSMS) for cleaning and analysis, Power BI for the two-page dashboard.
- **Cleaning:** interest rates and revolving utilisation arrived as text with a `%` sign, and term as text with a leading space, so they were converted with `TRY_CAST`. Issue dates were kept as text and the year extracted (opening the file in Excel would have corrupted them). Free-text and personal columns (descriptions, URLs, job titles, zip codes) were left out of the analysis view.
- **Import lesson:** the long free-text `desc` column broke the default import (string truncation), so it was loaded as `nvarchar(max)`.

## 3. Insights

1. **Grades priced risk well.** The charge-off rate rises from 6.0% (grade A) to 33.8% (grade G), and the average interest rate rises with it (7.3% to 21.3%). Net return also rises, from 7.2% to 13.9%.

| Grade | Loans | Charged off | Avg rate | Net return |
|---|---|---|---|---|
| A | 10,045 | 6.0% | 7.3% | 7.2% |
| B | 11,675 | 12.2% | 11.0% | 9.6% |
| C | 7,834 | 17.2% | 13.5% | 10.6% |
| D | 5,085 | 22.0% | 15.7% | 11.2% |
| E | 2,663 | 26.8% | 17.6% | 13.0% |
| F | 976 | 32.7% | 19.6% | 12.4% |
| G | 299 | 33.8% | 21.3% | 13.9% |

2. **Small-business loans were a blind spot.** They charged off at 27.1% (against 10.8% for credit-card loans) and earned a net return of just 0.5%. This is not explained by grade: within every grade, small-business loans charged off **6 to 15 points more** than other loans, at essentially the same interest rate.

| Grade | Other loans: charged off | Small business: charged off | Net return (other / small business) |
|---|---|---|---|
| A | 5.8% | 11.5% | 7.3% / 4.9% |
| B | 11.6% | 26.5% | 10.1% / -1.5% |
| C | 16.7% | 28.5% | 11.1% / 2.0% |
| D | 21.3% | 33.0% | 12.1% / -1.6% |
| E | 26.2% | 35.1% | 13.8% / 2.5% |
| F | 31.9% | 40.0% | 13.7% / -2.9% |
| G | 31.7% | 44.7% | 16.2% / -1.5% |

3. **In dollars, the damage is concentrated in grades B to G.** Lenders put **$19.4M** into small-business loans in grades B to G and got back $44,000 *less* than they lent (-0.2%). Other loans in the same grades earned **11.4%**. If those loans had earned that, profit would have been roughly $2.2M (an illustrative estimate, not a forecast).

| Segment | Grades | Loans | Lent | Net profit | Net return |
|---|---|---|---|---|---|
| All other purposes | A | 9,698 | $81.2M | +$5.91M | 7.3% |
| All other purposes | B to G | 27,125 | $312.3M | +$35.75M | 11.4% |
| Small business | A | 347 | $3.1M | +$0.15M | 4.9% |
| Small business | B to G | 1,407 | $19.4M | -$0.04M | -0.2% |

4. **Debt-to-income is a weak signal.** The charge-off rate moves only from 12.6% (DTI under 10) to 17.0% (DTI 20 to 24.9), and net return stays near 10%.
5. **60-month loans are far riskier.** They charge off at 25.3% against 11.1% for 36-month loans. Their higher raw return (11.9% vs 9.1%) is earned over a longer period, so it probably overstates their advantage.
6. **The year pattern is noisy.** Charge-off rates ranged from 12.6% (2009) to 17.9% (2007), and the early years rest on small samples (251 loans in 2007).

## 4. Recommendations

| # | Recommendation | Evidence | How to measure it |
|---|---|---|---|
| 1 | **Reprice or restrict small-business loans in grades B to G.** | $19.4M lent at -0.2% return, against 11.4% for other loans in the same grades. Charge-offs are 6 to 15 points higher at the same rate. | Net return and charge-off rate by purpose within grade |
| 2 | **Keep grade-based pricing.** | Net return rises from 7.2% (A) to 13.9% (G), so blanket tightening of lower grades isn't supported. | Net return by grade each quarter |
| 3 | **Use debt-to-income as a secondary check only.** | Charge-off moves only 4 points across the main bands, and the rate already rises with risk. | Charge-off rate by DTI band, within grade |
| 4 | **Review the 60-month book using an annualised return** before changing policy. | 25.3% charged off vs 11.1%, but the raw return flatters long loans. | Annualised return, 36 vs 60 months, within grade |

**Next analysis:** compare small-business loans with other loans of the same grade *and* term, and compute an annualised return.

## 5. Limitations

1. **2007 to 2011 only.** The findings describe these years, not Lending Club today.
2. **Completed loans only.** Loans still being repaid were excluded, which can bias the charge-off rate.
3. **Net return is rough.** It ignores the timing of payments and platform fees, and it flatters longer loans.
4. **Association, not cause.** The data shows small-business borrowers charged off more often. It can't say why.
5. **Small samples.** Grades F and G (976 and 299 loans), the early issue years, and some purposes (for example renewable energy, which has fewer than 200 loans) rest on few loans. The 25+ DTI band has 625 loans.
6. **The sizing in insight 3** assumes comparable loans would have earned the same return, so treat it as an estimate.

## 6. Dashboard

- **Overview page:** KPI cards (completed loans, charge-off rate, net return, average interest rate), net return by purpose, charge-off rate by grade, charge-off rate by grade for small business vs other loans, and a table of what the money did. Slicers for purpose, term and issue year.
- **Insights page:** charge-off rate by term, issue year and DTI band, plus the four recommendations.

## 7. Files

| File | Purpose |
|---|---|
| `LendingClub.pbix` | Power BI report |
| `LendingClub_Queries.sql` | Analysis view and queries B01 to B07 |
| `dashboard-images/` | Dashboard screenshots |

**Tools:** SQL Server (SSMS), Power BI Desktop, DAX.

### SQL Highlights (`LendingClub_Queries.sql`)

| Section | Purpose |
|---|---|
| Create view | Completed loans only, text fields converted to numbers, charge-off flag, personal and free-text columns removed |
| B01 Grade | Charge-off rate, interest rate and net return by grade |
| B02 Term | 36 vs 60 months |
| B03 Purpose | Riskiest purposes (at least 200 loans) |
| B04 Within-grade test | Small business vs other loans in the same grade |
| B05 DTI bands | `CASE` banding of debt-to-income |
| B06 Issue year | Trend by year |
| B07 Dollars | Amount lent, repaid and net profit by segment and grade group |

### DAX highlights

- `Charge-off Rate = DIVIDE(SUM(loans[is_charged_off]), COUNTROWS(loans))`
- `Net Return = DIVIDE(Net Profit, Amount Lent)`, where `Net Profit = SUM(total_pymnt) - SUM(funded_amnt)`
- Calculated columns: `Loan Segment` (small business vs other), `Grade Group` (A vs B to G), `DTI Band`.

## 8. Getting Started

1. Download `LendingClub.pbix` from this repository and open it in Power BI Desktop.
2. To rerun the SQL, download the loan data from Kaggle and import it into SQL Server as `loans_raw`: tick **Allow Nulls** on every column, set `desc`, `title`, `emp_title` and `url` to `nvarchar(max)`, and keep the date and percentage columns as text.
3. Run `LendingClub_Queries.sql` from top to bottom.
