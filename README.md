# Part II, Item 1: Bitcoin Return Distribution Fitting

## Objective

To determine which probability distribution best fits the one-minute returns of Bitcoin quoted in United States dollars (BTC/USD) from January 1, 2012, to September 15, 2026.

## Data Source
- Cryptocurrency: Bitcoin (BTC/USD)
- Data interval: One minute
- Requested period: January 1, 2012 – September 15, 2026
- Data provider: Bitstamp
- Historical data repository: https://ff137.github.io/bitstamp-btcusd-minute-data/
- Reference article: https://medium.com/analytics-vidhya/modelling-bitcoin-returns-e6c3d286c00f

The actual available date range must be verified from the downloaded dataset before reporting the final results.

## Methodology

The analysis was conducted using R. The midpoint price was calculated using the average of the high and low prices:

M(t) = [High(t) + Low(t)] / 2
|
Simple returns were calculated from consecutive midpoint prices:

R(t) = [M(t) - M(t-1)] / M(t-1)

Four candidate probability distributions were fitted to the returns:

1. Normal distribution
2. Student's t-distribution
3. Laplace distribution
4. Logistic distribution

The fitted distributions were compared using the Kolmogorov–Smirnov (KS) distance. The distribution with the smallest KS distance was ranked as the best fit among the candidates tested.

## Results

The current results table ranks the Student's t-distribution first, with a KS distance of 0.091298. The Laplace, Logistic, and Normal distributions follow, with KS distances of 0.098125, 0.122429, and 0.208609, respectively.

These values are descriptive goodness-of-fit comparisons. They are not formal significance-test results.

## Interpretation

Among the four candidate distributions, the Student's t-distribution has the smallest KS distance and provides the closest empirical fit according to the selected comparison criterion. This is consistent with the possibility of heavier tails in financial returns. However, the fitted degrees of freedom are close to the lower bound imposed by the estimation procedure, so the parameter estimate requires further checking.

## Files
- code/bitcoin_return_distribution_fit.R – R source code
- results/btc_distribution_fit_results.csv – Distribution ranking and estimated parameters
- results/btc_returns_fitted_distributions.png – Histogram and fitted density curves
- results/btc_returns_cdf_comparison.png – Empirical and fitted cumulative distribution functions

## Reproducibility

Run the R script in RStudio with an internet connection. Install the required packages if they are not already installed. The script downloads the source data, calculates returns, fits the candidate distributions, and generates the results table and plots.

## Limitations

The findings depend on the available dataset, data quality, return definition, candidate distributions, and parameter-fitting procedure. Missing minute-level observations and the treatment of zero returns may affect the results. The reported date coverage must be checked before drawing conclusions about the entire requested period.

# Section II, Part 2: Shapiro–Wilk Normality Test for Ethereum Returns

## Objective

The objective of this analysis is to test whether Ethereum (ETH/USD) five-minute log returns follow a normal distribution using the Shapiro–Wilk normality test.

## Dataset and Source

The dataset used is Kraken's historical OHLCVT data for the ETH/USD trading pair. OHLCVT data contains timestamp, open, high, low, close, volume, and trade-count fields.

- **Dataset:** Kraken ETH/USD five-minute OHLCVT historical data
- **Source:** [Kraken downloadable historical OHLCVT data](https://support.kraken.com/in/articles/360047124832-downloadable-historical-ohlcvt-open-high-low-close-volume-trades-data)
- **Local data file:** `ETHUSD_5.csv`
- **Requested assessment period:** August 7, 2015, to September 15, 2026
- **Available data period:** August 7, 2015, to June 30, 2026

Note: The raw CSV file is stored locally and is not included in this repository because of its large file size. It can be obtained from the source linked above.

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
