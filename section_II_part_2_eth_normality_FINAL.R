# Section II, Part 2: Shapiro-Wilk Normality Test
# Ethereum (ETH/USD) five-minute trading data
#
# Input file required in the working directory:
#   ETHUSD_5.csv
#
# The available Kraken archive currently ends on 2026-06-30.
# The requested assessment period ends on 2026-09-15, so this script
# reports the actual available coverage and does not claim to test
# the missing dates.

# 1. Read the data ---------------------------------------------------------
eth <- read.csv("ETHUSD_5.csv", header = FALSE)

if (ncol(eth) != 7) {
  stop("Expected 7 columns in ETHUSD_5.csv: timestamp, open, high, low, close, volume, trades.")
}

names(eth) <- c(
  "timestamp", "open", "high", "low",
  "close", "volume", "trades"
)

# 2. Convert timestamps and select the requested date window --------------
eth$date <- as.POSIXct(
  eth$timestamp,
  origin = "1970-01-01",
  tz = "UTC"
)

start_date <- as.POSIXct("2015-08-07 00:00:00", tz = "UTC")
end_date <- as.POSIXct("2026-09-15 23:59:59", tz = "UTC")

eth <- eth[eth$date >= start_date & eth$date <= end_date, ]
eth <- eth[order(eth$timestamp), ]

if (nrow(eth) < 2) {
  stop("Not enough data in the selected date range.")
}

# 3. Calculate log returns and keep only exact five-minute intervals ------
log_returns <- diff(log(eth$close))
time_gaps <- diff(eth$timestamp)

returns <- log_returns[time_gaps == 300]
returns <- returns[is.finite(returns)]

if (length(returns) < 3) {
  stop("Fewer than 3 valid five-minute returns; Shapiro-Wilk test cannot run.")
}

# 4. Randomly sample up to 5,000 returns for the Shapiro-Wilk test ----------
# R's shapiro.test() accepts 3 to 5,000 observations.
set.seed(103)

if (length(returns) > 5000) {
  test_returns <- sample(returns, 5000)
} else {
  test_returns <- returns
}

# 5. Run the test ----------------------------------------------------------
test_result <- shapiro.test(test_returns)

# 6. Summarize observed coverage and results -------------------------------
first_available <- min(eth$date, na.rm = TRUE)
last_available <- max(eth$date, na.rm = TRUE)

summary_table <- data.frame(
  Item = c(
    "Asset / trading pair",
    "Requested start date",
    "Requested end date",
    "First date available in filtered file",
    "Last date available in filtered file",
    "Valid returns from exact 5-minute intervals",
    "Number of observations tested",
    "Shapiro-Wilk W statistic",
    "p-value",
    "Significance level",
    "Decision"
  ),
  Result = c(
    "Ethereum (ETH/USD)",
    "2015-08-07",
    "2026-09-15",
    format(first_available, "%Y-%m-%d", tz = "UTC"),
    format(last_available, "%Y-%m-%d", tz = "UTC"),
    as.character(length(returns)),
    as.character(length(test_returns)),
    format(unname(test_result$statistic), digits = 7),
    format.pval(test_result$p.value, digits = 7, eps = 2.2e-16),
    "0.05",
    if (test_result$p.value < 0.05) {
      "Reject the null hypothesis of normality"
    } else {
      "Fail to reject the null hypothesis of normality"
    }
  ),
  stringsAsFactors = FALSE
)

write.csv(summary_table, "eth_shapiro_results.csv", row.names = FALSE)

# Save a readable text report with hypotheses and interpretation.
interpretation <- if (test_result$p.value < 0.05) {
  paste(
    "Because the p-value is below 0.05, reject the null hypothesis.",
    "The sampled Ethereum five-minute log returns show strong evidence",
    "of departure from a normal distribution."
  )
} else {
  paste(
    "Because the p-value is at least 0.05, fail to reject the null hypothesis.",
    "This does not prove that the returns are normally distributed."
  )
}

report_lines <- c(
  "SECTION II, PART 2: SHAPIRO-WILK NORMALITY TEST",
  "Asset: Ethereum (ETH/USD)",
  paste("Requested period: 2015-08-07 through 2026-09-15"),
  paste("Available period in filtered file:",
        format(first_available, "%Y-%m-%d", tz = "UTC"), "through",
        format(last_available, "%Y-%m-%d", tz = "UTC")),
  paste("Valid exact five-minute returns:", length(returns)),
  paste("Observations tested:", length(test_returns)),
  paste("W statistic:", format(unname(test_result$statistic), digits = 7)),
  paste("p-value:", format.pval(test_result$p.value, digits = 7, eps = 2.2e-16)),
  "Significance level: 0.05",
  "H0: The sampled log returns follow a normal distribution.",
  "H1: The sampled log returns do not follow a normal distribution.",
  paste("Decision:", summary_table$Result[summary_table$Item == "Decision"]),
  paste("Interpretation:", interpretation),
  "",
  "Limitation: The available Kraken dataset ends on 2026-06-30, before the",
  "requested end date of 2026-09-15. The analysis therefore applies only to",
  "the available observation period and does not include the missing dates."
)

writeLines(report_lines, "eth_shapiro_report.txt")

# 7. Save plots -------------------------------------------------------------
png("eth_returns_histogram.png", width = 1200, height = 800, res = 150)
hist(
  test_returns,
  breaks = 50,
  main = "Distribution of Ethereum Five-Minute Log Returns",
  xlab = "Log return",
  ylab = "Frequency"
)
dev.off()

png("eth_returns_qqplot.png", width = 1200, height = 800, res = 150)
qqnorm(
  test_returns,
  main = "Q-Q Plot of Ethereum Five-Minute Log Returns",
  xlab = "Theoretical normal quantiles",
  ylab = "Sample quantiles"
)
qqline(test_returns, col = "red", lwd = 2)
dev.off()

# 8. Print results to the R console ----------------------------------------
cat("\n--- Ethereum Shapiro-Wilk Test Summary ---\n")
print(summary_table, row.names = FALSE)
cat("\n--- Full Shapiro-Wilk Test ---\n")
print(test_result)
cat("\nFiles saved in the current working directory:\n")
cat("- eth_shapiro_results.csv\n")
cat("- eth_shapiro_report.txt\n")
cat("- eth_returns_histogram.png\n")
cat("- eth_returns_qqplot.png\n")
