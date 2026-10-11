# ============================================================
# PPD Summative Assessment - Section II, Part 2
# Shapiro-Wilk Normality Test for Five-Minute ETH/USD Returns
# ============================================================

# DATA SOURCE:
# Kraken downloadable historical OHLCVT data:
# https://support.kraken.com/hc/en-us/articles/360047124832-downloadable-historical-ohlcvt-open-high-low-volume-trades-data
#
# The extracted ETH/USD 5-minute CSV is expected to have no header
# and seven columns:
# timestamp, open, high, low, close, volume, trades
#
# IMPORTANT:
# Set data_file to the path of your extracted ETH/USD 5-minute CSV.
# Kraken's currently published full archive may not cover the entire
# assessment end date (September 15, 2026). The script reports the
# actual data coverage and warns if it is incomplete.

# -----------------------------
# 1. Set file path and dates
# -----------------------------
data_file <- "PATH/TO/ETHUSD_5.csv"  # <-- CHANGE THIS PATH

start_date <- as.POSIXct("2015-08-07 00:00:00", tz = "UTC")
end_date_exclusive <- as.POSIXct("2026-09-16 00:00:00", tz = "UTC")
alpha <- 0.05
test_sample_size <- 5000

# -----------------------------
# 2. Import and validate data
# -----------------------------
if (!file.exists(data_file)) {
  stop(
    "Data file not found. Update 'data_file' with the location of the ",
    "extracted ETH/USD 5-minute CSV file."
  )
}

ohlc <- read.csv(data_file, header = FALSE, stringsAsFactors = FALSE)

if (ncol(ohlc) < 7) {
  stop("The CSV must contain at least 7 columns: timestamp, open, high, low, close, volume, trades.")
}

ohlc <- ohlc[, 1:7]
names(ohlc) <- c("timestamp", "open", "high", "low", "close", "volume", "trades")

# Kraken timestamps are Unix timestamps in seconds.
ohlc$timestamp <- as.POSIXct(
  as.numeric(ohlc$timestamp),
  origin = "1970-01-01",
  tz = "UTC"
)

numeric_cols <- c("open", "high", "low", "close", "volume", "trades")
for (col in numeric_cols) {
  ohlc[[col]] <- as.numeric(ohlc[[col]])
}

ohlc <- ohlc[!is.na(ohlc$timestamp) & !is.na(ohlc$close) & ohlc$close > 0, ]
ohlc <- ohlc[order(ohlc$timestamp), ]
ohlc <- ohlc[!duplicated(ohlc$timestamp), ]

if (nrow(ohlc) < 4) {
  stop("Not enough valid price observations were found in the file.")
}

# -----------------------------
# 3. Calculate five-minute log returns
# -----------------------------
# A log return is ln(Close_t / Close_(t-1)).
# Keep only consecutive candles exactly 5 minutes apart. Kraken notes
# that intervals without trades may be absent from its OHLCVT files.
ohlc$previous_timestamp <- c(as.POSIXct(NA, origin = "1970-01-01", tz = "UTC"),
                              ohlc$timestamp[-nrow(ohlc)])
ohlc$previous_close <- c(NA, ohlc$close[-nrow(ohlc)])
ohlc$interval_seconds <- as.numeric(
  difftime(ohlc$timestamp, ohlc$previous_timestamp, units = "secs")
)
ohlc$log_return <- log(ohlc$close / ohlc$previous_close)

returns_data <- ohlc[
  !is.na(ohlc$log_return) &
    is.finite(ohlc$log_return) &
    ohlc$interval_seconds == 300 &
    ohlc$timestamp >= start_date &
    ohlc$timestamp < end_date_exclusive,
  c("timestamp", "close", "log_return")
]

if (nrow(returns_data) < 3) {
  stop("Fewer than 3 valid consecutive five-minute returns fall within the requested date range.")
}

# -----------------------------
# 4. Check date coverage
# -----------------------------
actual_first <- min(returns_data$timestamp)
actual_last <- max(returns_data$timestamp)

cat("\n========== DATA COVERAGE ==========\n")
cat("Requested start (UTC):", format(start_date), "\n")
cat("Requested end (UTC):  ", format(end_date_exclusive - 1, "%Y-%m-%d"), "\n")
cat("First return in file: ", format(actual_first), "\n")
cat("Last return in file:  ", format(actual_last), "\n")
cat("Valid five-minute returns in requested window:", nrow(returns_data), "\n")

if (actual_first > start_date + 86400) {
  warning("The dataset starts later than the requested start date. Confirm the file covers August 7, 2015.")
}
if (actual_last < end_date_exclusive - 300) {
  warning(
    "The dataset does not reach September 15, 2026. Report the actual coverage honestly; ",
    "do not claim that the requested end date was fully analyzed."
  )
}

# Save the cleaned return series used in the analysis.
write.csv(returns_data, "eth_usd_5min_log_returns.csv", row.names = FALSE)

# -----------------------------
# 5. Descriptive statistics
# -----------------------------
x_all <- returns_data$log_return

descriptive_stats <- data.frame(
  Measure = c("Number of valid five-minute returns", "Mean log return",
              "Standard deviation", "Variance", "Minimum", "Maximum"),
  Value = c(length(x_all), mean(x_all), sd(x_all), var(x_all),
            min(x_all), max(x_all))
)

cat("\n========== DESCRIPTIVE STATISTICS ==========\n")
print(descriptive_stats, row.names = FALSE)
write.csv(descriptive_stats, "eth_descriptive_statistics.csv", row.names = FALSE)

# -----------------------------
# 6. Shapiro-Wilk normality test
# -----------------------------
# R's shapiro.test() accepts 3 to 5,000 non-missing observations.
# If there are more than 5,000 returns, take a reproducible random
# sample from the full valid series to represent the entire period.
set.seed(103)
if (length(x_all) > test_sample_size) {
  x_test <- sample(x_all, size = test_sample_size, replace = FALSE)
  sampling_note <- paste(
    "A reproducible random sample of", test_sample_size,
    "returns was tested because R's shapiro.test() supports at most 5,000 observations."
  )
} else {
  x_test <- x_all
  sampling_note <- paste("All", length(x_test), "available valid returns were tested.")
}

if (length(x_test) < 3 || length(unique(x_test)) < 2) {
  stop("The selected sample is insufficient for the Shapiro-Wilk test.")
}

sw_result <- shapiro.test(x_test)

cat("\n========== SHAPIRO-WILK TEST ==========\n")
cat("Null hypothesis (H0): The sampled ETH/USD five-minute log returns follow a normal distribution.\n")
cat("Alternative hypothesis (H1): The sampled ETH/USD five-minute log returns do not follow a normal distribution.\n")
cat("Significance level:", alpha, "\n")
cat("Number of observations tested:", length(x_test), "\n")
cat("Sampling note:", sampling_note, "\n\n")
print(sw_result)

if (sw_result$p.value < alpha) {
  decision <- "Reject H0"
  interpretation <- paste0(
    "Since p-value = ", format.pval(sw_result$p.value, digits = 4),
    " is less than ", alpha,
    ", reject the null hypothesis. The tested sample provides statistically significant evidence ",
    "that the five-minute ETH/USD log returns are not normally distributed."
  )
} else {
  decision <- "Fail to reject H0"
  interpretation <- paste0(
    "Since p-value = ", format.pval(sw_result$p.value, digits = 4),
    " is greater than or equal to ", alpha,
    ", fail to reject the null hypothesis. The test does not provide sufficient evidence ",
    "against normality; this does not prove that the returns are normally distributed."
  )
}

test_results <- data.frame(
  Test = "Shapiro-Wilk normality test",
  W_statistic = unname(sw_result$statistic),
  p_value = sw_result$p.value,
  alpha = alpha,
  observations_tested = length(x_test),
  decision = decision,
  interpretation = interpretation,
  sampling_note = sampling_note,
  first_return_date_UTC = format(actual_first),
  last_return_date_UTC = format(actual_last)
)

cat("\n========== INTERPRETATION ==========\n")
cat(interpretation, "\n")
write.csv(test_results, "eth_shapiro_wilk_results.csv", row.names = FALSE)

# -----------------------------
# 7. Visualizations
# -----------------------------
# Histogram: display the central 98% to make the distribution's shape
# easier to inspect; the statistical test still uses x_test as selected above.
hist_limits <- quantile(x_all, probs = c(0.01, 0.99), na.rm = TRUE)
png("eth_returns_histogram.png", width = 1200, height = 800, res = 140)
hist(
  x_all,
  breaks = 100,
  xlim = hist_limits,
  probability = TRUE,
  main = "Distribution of ETH/USD Five-Minute Log Returns",
  xlab = "Log return",
  col = "lightgray",
  border = "white"
)
curve(
  dnorm(x, mean = mean(x_all), sd = sd(x_all)),
  add = TRUE,
  lwd = 2,
  col = "blue"
)
legend(
  "topright",
  legend = c("Observed returns (histogram)", "Normal curve"),
  lwd = c(NA, 2),
  pch = c(15, NA),
  col = c("lightgray", "blue"),
  bty = "n"
)
dev.off()

png("eth_returns_qq_plot.png", width = 1200, height = 800, res = 140)
qqnorm(x_test, main = "Normal Q-Q Plot of ETH/USD Five-Minute Log Returns")
qqline(x_test, col = "blue", lwd = 2)
dev.off()

cat("\nFiles saved:\n")
cat("- eth_usd_5min_log_returns.csv\n")
cat("- eth_descriptive_statistics.csv\n")
cat("- eth_shapiro_wilk_results.csv\n")
cat("- eth_returns_histogram.png\n")
cat("- eth_returns_qq_plot.png\n")
cat("\nAnalysis complete.\n")
