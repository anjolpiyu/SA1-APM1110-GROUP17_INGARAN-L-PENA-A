# Probability and Probability Distributions - Summative Assessment
# Part II, Item 1: Fit probability distributions to BTC/USD one-minute returns.
# Method follows Moro (2021): construct returns and compare goodness of fit.
# Data source: Bitstamp BTC/USD 1-minute OHLC history and daily updates.
#
# IMPORTANT:
# 1. The historical bulk file covers 2012-01-01 to 2025-01-07. The updates file
#    is expected to extend the series toward 2026-09-15. This script checks dates.
# 2. The KS D statistic is used descriptively to rank fitted distributions.
#    Since parameters are estimated from the same data, ordinary KS p-values
#    would not be calibrated; do not interpret them as formal p-values.
# 3. Returns use the article's MID price: (High + Low) / 2, then simple return
#    (MID_t - MID_(t-1)) / MID_(t-1), not log returns.

# Install once if needed:
# install.packages(c("data.table", "ggplot2"))

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

start_date <- as.POSIXct("2012-01-01 00:00:00", tz = "UTC")
end_date   <- as.POSIXct("2026-09-15 23:59:59", tz = "UTC")

hist_url <- paste0(
  "https://raw.githubusercontent.com/ff137/bitstamp-btcusd-minute-data/",
  "main/data/historical/btcusd_bitstamp_1min_2012-2025.csv.gz"
)
updates_url <- paste0(
  "https://raw.githubusercontent.com/ff137/bitstamp-btcusd-minute-data/",
  "main/data/updates/btcusd_bitstamp_1min_latest.csv"
)

hist_file <- "btcusd_bitstamp_1min_2012-2025.csv.gz"
updates_file <- "btcusd_bitstamp_1min_latest.csv"

download_if_needed <- function(url, dest) {
  if (!file.exists(dest)) {
    message("Downloading: ", basename(dest))
    download.file(url, destfile = dest, mode = "wb", quiet = FALSE)
  }
}

download_if_needed(hist_url, hist_file)
download_if_needed(updates_url, updates_file)

historical <- fread(hist_file)
updates <- fread(updates_file)
prices <- rbindlist(list(historical, updates), fill = TRUE)
prices <- unique(prices, by = "timestamp")
setorder(prices, timestamp)

required_cols <- c("timestamp", "high", "low")
if (!all(required_cols %in% names(prices))) {
  stop("Data files must contain timestamp, high, and low columns.")
}

prices[, datetime := as.POSIXct(as.numeric(timestamp),
                                origin = "1970-01-01", tz = "UTC")]
prices <- prices[datetime >= start_date & datetime <= end_date]
prices[, `:=`(high = as.numeric(high), low = as.numeric(low))]
prices[, mid := (high + low) / 2]
prices <- prices[is.finite(mid) & mid > 0]
setorder(prices, datetime)

# Compute consecutive minute-to-minute returns. Remove invalid values.
prices[, return := (mid - shift(mid)) / shift(mid)]
returns <- prices[is.finite(return), return]
if (length(returns) < 1000) stop("Too few valid returns; check downloaded data.")

message("First timestamp: ", format(min(prices$datetime), tz = "UTC"))
message("Last timestamp:  ", format(max(prices$datetime), tz = "UTC"))
message("Price rows in date range: ", nrow(prices))
message("Valid one-minute returns: ", length(returns))
if (max(prices$datetime) < end_date - 86400) {
  warning("Downloaded data does not reach September 15, 2026. Report the actual end date.")
}

# Numerical log-likelihood fitting for four continuous distributions.
# All are defined on the real line and can model positive and negative returns.
fit_normal <- function(x) {
  mu <- mean(x); sig <- sd(x)
  list(name = "Normal", par = c(mean = mu, sd = sig),
       cdf = function(z) pnorm(z, mu, sig),
       density = function(z) dnorm(z, mu, sig))
}

fit_laplace <- function(x) {
  mu <- median(x)
  b <- mean(abs(x - mu))  # Laplace MLE scale
  list(name = "Laplace", par = c(location = mu, scale = b),
       cdf = function(z) ifelse(z < mu, 0.5 * exp((z-mu)/b),
                                1 - 0.5 * exp(-(z-mu)/b)),
       density = function(z) exp(-abs(z-mu)/b)/(2*b))
}

fit_logistic <- function(x) {
  nll <- function(par) {
    loc <- par[1]; scale <- exp(par[2])
    -sum(dlogis(x, location = loc, scale = scale, log = TRUE))
  }
  opt <- optim(c(median(x), log(sd(x) * sqrt(3) / pi)),
               nll, method = "BFGS")
  loc <- opt$par[1]; sc <- exp(opt$par[2])
  list(name = "Logistic", par = c(location = loc, scale = sc),
       cdf = function(z) plogis(z, location = loc, scale = sc),
       density = function(z) dlogis(z, location = loc, scale = sc))
}

fit_student_t <- function(x) {
  # Fit location, scale, and degrees of freedom by maximum likelihood.
  nll <- function(par) {
    loc <- par[1]
    scale <- exp(par[2])
    df <- 2 + exp(par[3]) # constrain df > 2 for finite variance
    -sum(dt((x - loc) / scale, df = df, log = TRUE) - log(scale))
  }
  opt <- optim(c(median(x), log(sd(x)), log(8 - 2)),
               nll, method = "Nelder-Mead",
               control = list(maxit = 2000))
  loc <- opt$par[1]; sc <- exp(opt$par[2]); df <- 2 + exp(opt$par[3])
  list(name = "Student-t", par = c(location = loc, scale = sc, df = df),
       cdf = function(z) pt((z-loc)/sc, df = df),
       density = function(z) dt((z-loc)/sc, df = df)/sc)
}

# Fit to the complete data. The ECDF/KS calculation uses sorted observations.
fits <- list(fit_normal(returns), fit_student_t(returns),
             fit_laplace(returns), fit_logistic(returns))

x_sorted <- sort(returns)
n <- length(x_sorted)
empirical_cdf <- seq_len(n) / n

ks_distance <- function(cdf_fun) {
  fitted_cdf <- pmin(pmax(cdf_fun(x_sorted), 0), 1)
  d_plus <- max(empirical_cdf - fitted_cdf)
  d_minus <- max(fitted_cdf - (seq_len(n) - 1) / n)
  max(d_plus, d_minus)
}

results <- rbindlist(lapply(fits, function(f) {
  data.table(
    Distribution = f$name,
    Parameters = paste(names(f$par), signif(f$par, 6),
                       sep = "=", collapse = "; "),
    KS_D = ks_distance(f$cdf)
  )
}))
setorder(results, KS_D)
results[, Rank := .I]
setcolorder(results, c("Rank", "Distribution", "Parameters", "KS_D"))
print(results)
fwrite(results, "btc_distribution_fit_results.csv")

# Histogram with fitted densities (full data; zoom is only for readability).
plot_data <- data.table(return = returns)
density_grid <- data.table(return = seq(
  quantile(returns, 0.001, na.rm = TRUE),
  quantile(returns, 0.999, na.rm = TRUE), length.out = 1200
))
density_grid <- rbindlist(lapply(fits, function(f) {
  data.table(return = density_grid$return,
             density = f$density(density_grid$return),
             Distribution = f$name)
}))

p1 <- ggplot(plot_data, aes(x = return)) +
  geom_histogram(aes(y = after_stat(density)), bins = 180,
                 fill = "skyblue", color = "white") +
  geom_line(data = density_grid,
            aes(x = return, y = density, color = Distribution),
            linewidth = 0.8) +
  coord_cartesian(xlim = quantile(returns, c(0.001, 0.999), na.rm = TRUE)) +
  labs(title = "BTC/USD One-Minute Returns and Fitted Distributions",
       subtitle = "Bitstamp MID price; x-axis clipped to 0.1%–99.9% quantiles for visibility",
       x = "Simple one-minute return", y = "Density", color = "Distribution") +
  theme_minimal()
ggsave("btc_returns_fitted_distributions.png", p1, width = 10, height = 6, dpi = 300)

# Empirical CDF versus fitted CDF, sampled at evenly spaced quantiles for plotting.
plot_idx <- unique(round(seq(1, n, length.out = min(5000, n))))
cdf_plot <- data.table(
  return = x_sorted[plot_idx],
  Empirical = empirical_cdf[plot_idx]
)
cdf_long <- rbindlist(lapply(fits, function(f) {
  data.table(return = x_sorted[plot_idx],
             CDF = f$cdf(x_sorted[plot_idx]),
             Distribution = f$name)
}))
p2 <- ggplot() +
  geom_step(data = cdf_plot, aes(x = return, y = Empirical),
            color = "black", linewidth = 0.7) +
  geom_line(data = cdf_long, aes(x = return, y = CDF, color = Distribution),
            linewidth = 0.7) +
  coord_cartesian(xlim = quantile(returns, c(0.001, 0.999), na.rm = TRUE)) +
  labs(title = "Empirical CDF Compared with Fitted CDFs",
       x = "Simple one-minute return", y = "Cumulative probability",
       color = "Distribution") +
  theme_minimal()
ggsave("btc_returns_cdf_comparison.png", p2, width = 10, height = 6, dpi = 300)

cat("\nBest fit by the smallest empirical KS D:", results$Distribution[1], "\n")
cat("KS D:", format(results$KS_D[1], digits = 7), "\n")
cat("Mean return:", mean(returns), "\n")
cat("Standard deviation:", sd(returns), "\n")
cat("\nFiles saved:\n- btc_distribution_fit_results.csv\n- btc_returns_fitted_distributions.png\n- btc_returns_cdf_comparison.png\n")
