# Section II, Part 2: Shapiro-Wilk Normality Test
# Ethereum 5-minute trading data

# 1. Read the data
eth <- read.csv("ETHUSD_5.csv", header = FALSE)

names(eth) <- c(
  "timestamp", "open", "high", "low",
  "close", "volume", "trades"
)

# 2. Convert timestamps to UTC dates
eth$date <- as.POSIXct(
  eth$timestamp,
  origin = "1970-01-01",
  tz = "UTC"
)

# 3. Filter the required date range
start_date <- as.POSIXct("2015-08-07 00:00:00", tz = "UTC")
end_date <- as.POSIXct("2026-09-15 23:59:59", tz = "UTC")

eth <- eth[eth$date >= start_date & eth$date <= end_date, ]
eth <- eth[order(eth$timestamp), ]

# 4. Calculate log returns between consecutive records
log_returns <- diff(log(eth$close))
time_gaps <- diff(eth$timestamp)

# Keep only returns where records are exactly 5 minutes apart
returns <- log_returns[time_gaps == 300]
returns <- returns[is.finite(returns)]

# 5. Print the data summary
cat("First date:", format(min(eth$date), "%Y-%m-%d"), "\n")
cat("Last date:", format(max(eth$date), "%Y-%m-%d"), "\n")
cat("Valid 5-minute returns:", length(returns), "\n")

# 6. Shapiro-Wilk test
# R allows between 3 and 5,000 observations
set.seed(103)

if (length(returns) > 5000) {
  test_returns <- sample(returns, 5000)
} else {
  test_returns <- returns
}

if (length(test_returns) >= 3) {
  result <- shapiro.test(test_returns)
  print(result)
} else {
  cat("Not enough valid observations for the test.\n")
}

# 7. Visual checks
hist(
  test_returns,
  main = "Distribution of Ethereum Log Returns",
  xlab = "Log Returns"
)

qqnorm(test_returns, main = "Q-Q Plot of Ethereum Log Returns")
qqline(test_returns, col = "red")
