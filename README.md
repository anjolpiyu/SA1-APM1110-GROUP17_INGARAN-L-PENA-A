# Section II, Part 2: Shapiro–Wilk Normality Test for Ethereum Returns

## Objective

The objective of this analysis is to test whether Ethereum (ETH/USD) five-minute log returns follow a normal distribution using the Shapiro–Wilk normality test.

## Dataset and Source

The dataset used is Kraken's historical OHLCVT data for the ETH/USD trading pair. OHLCVT data contains timestamp, open, high, low, close, volume, and trade-count fields.

- **Source:** [Kraken downloadable historical OHLCVT data](https://support.kraken.com/in/articles/360047124832-downloadable-historical-ohlcvt-open-high-low-close-volume-trades-data)
- **Local data file:** `ETHUSD_5.csv`
- **Requested assessment period:** August 7, 2015, to September 15, 2026
- **Available data period:** August 7, 2015, to June 30, 2026

## Methodology

The CSV file was imported into R and its Unix timestamps were converted to UTC dates. The data was filtered to the requested assessment window and sorted by timestamp. Log returns were calculated from consecutive closing prices.

Only returns for which consecutive records were exactly 300 seconds (five minutes) apart were retained. This resulted in 998,244 valid five-minute returns.

R's `shapiro.test()` accepts between 3 and 5,000 observations. Therefore, a reproducible random sample of 5,000 returns was selected using `set.seed(103)` and tested. The significance level was set to 0.05.

## R Code

The analysis code is saved in [`section_II_part_2_eth_normality_FINAL.R`](section_II_part_2_eth_normality_FINAL.R).

Run the script with `ETHUSD_5.csv` in the R working directory. It generates the results table, a text report, a histogram, and a Q–Q plot.

## Results

| Measure | Result |
|---|---|
| Trading pair | Ethereum (ETH/USD) |
| First available date | August 7, 2015 |
| Last available date | June 30, 2026 |
| Valid returns from exact five-minute intervals | 998,244 |
| Observations tested | 5,000 |
| Shapiro–Wilk statistic, W | 0.64407 |
| p-value | Less than 2.2 × 10⁻¹⁶ |
| Significance level | 0.05 |
| Decision | Reject the null hypothesis of normality |

## Hypotheses

- **Null hypothesis (H₀):** The sampled Ethereum five-minute log returns follow a normal distribution.
- **Alternative hypothesis (H₁):** The sampled Ethereum five-minute log returns do not follow a normal distribution.

## Interpretation and Conclusion

The Shapiro–Wilk test produced a statistic of W = 0.64407 and a p-value below 0.05. Therefore, the null hypothesis is rejected. The test provides strong statistical evidence that the sampled Ethereum five-minute log returns do not follow a normal distribution. This conclusion applies to the 5,000 sampled returns, rather than all 998,244 valid returns being tested individually.

## Graphs and Output Files

- `eth_shapiro_results.csv` — statistical results table
- `eth_shapiro_report.txt` — text summary of the test and interpretation
- `eth_returns_histogram.png` — histogram of sampled log returns
- `eth_returns_qqplot.png` — normal Q–Q plot of sampled log returns

## Limitation

The assessment requests data from August 7, 2015, through September 15, 2026. However, the available Kraken archive used for this analysis ends on June 30, 2026. The missing records from July 1 through September 15, 2026, could not be obtained from an exact, compatible source during this analysis. Therefore, the test results apply to the available observation period only and should not be described as covering the entire requested date range.

## Reference

Kraken. (n.d.). *Downloadable historical OHLCVT (Open, High, Low, Close, Volume, Trades) data*. https://support.kraken.com/in/articles/360047124832-downloadable-historical-ohlcvt-open-high-low-close-volume-trades-data
