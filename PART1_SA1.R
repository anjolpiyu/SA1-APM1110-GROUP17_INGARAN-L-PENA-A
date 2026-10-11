# PLEASE INPUT THE EITHER question1(), univariate(), bivariate(), 
# and question3() to use it!
# reads a line of numbers (spaces or commas both work)
get_nums <- function(prompt) {
  line <- trimws(readline(prompt))
  return(as.numeric(strsplit(line, "[ ,]+")[[1]]))
}

# Question 1: probability a product is defective

question1 <- function() {
  ok <- FALSE
  while (ok == FALSE) {
    x <- as.numeric(strsplit(readline("Enter x1 x2 x3 (e.g. 0.3 0.4 0.3 or 30 40 30 for percent): "), " ")[[1]])
    if (any(x > 1)) {
      x <- x / 100   
    }
    if (length(x) != 3) {
      print("Please enter exactly 3 values")
    } else if (any(x < 0.10) || any(x > 0.40)) {
      print("Each x must be between 0.10 and 0.40 (10% and 40%)")
    } else if (abs(sum(x) - 1) > 0.000001) {
      print("The x values must add up to 1")
    } else {
      ok <- TRUE
    }
  }
  
  ok <- FALSE
  while (ok == FALSE) {
    y <- as.numeric(strsplit(readline("Enter y1 y2 y3 (e.g. 0.03 0.04 0.05 or 3 4 5 for percent): "), " ")[[1]])
    if (any(y > 1)) {
      y <- y / 100
    }
    if (length(y) != 3) {
      print("Please enter exactly 3 values")
    } else if (any(y < 0.01) || any(y > 0.05)) {
      print("Each y must be between 0.01 and 0.05 (1% and 5%)")
    } else if (abs(sum(y) - 0.12) > 0.000001) {
      print("The y values must add up to 0.12")
    } else {
      ok <- TRUE
    }
  }
  
  pd <- sum(x * y)
  cat("P(defective) =", pd, "\n")
  return(pd)
}

# Question 2: univariate discrete random variable

univariate <- function() {
  x <- as.numeric(strsplit(readline("Enter the values of X separated by spaces: "), " ")[[1]])
  p <- as.numeric(strsplit(readline("Enter the probabilities separated by spaces: "), " ")[[1]])
  
  if (length(x) != length(p)) {
    print("Error: need the same number of values and probabilities")
    return(NULL)
  }
  if (any(p < 0) || any(p > 1)) {
    print("Error: probabilities must be between 0 and 1")
    return(NULL)
  }
  if (abs(sum(p) - 1) > 0.000001) {
    print("Error: probabilities must add up to 1")
    return(NULL)
  }
  
  o <- order(x)
  x <- x[o]
  p <- p[o]
  
  mean_x <- sum(x * p)
  var_x <- sum(x^2 * p) - mean_x^2
  cat("Mean =", mean_x, "\n")
  cat("Variance =", var_x, "\n")
  
  par(mfrow = c(1, 2))
  plot(x, p, type = "h", main = "PDF", xlab = "x", ylab = "P(X = x)")
  plot(x, cumsum(p), type = "s", main = "CDF", xlab = "x", ylab = "P(X <= x)")
  par(mfrow = c(1, 1))
}


# Question 2: bivariate discrete random variable

bivariate <- function() {
  x <- as.numeric(strsplit(readline("Enter the values of X separated by spaces: "), " ")[[1]])
  y <- as.numeric(strsplit(readline("Enter the values of Y separated by spaces: "), " ")[[1]])
  
  joint <- matrix(0, nrow = length(x), ncol = length(y))
  for (i in 1:length(x)) {
    cat("Row for X =", x[i], "\n")
    joint[i, ] <- as.numeric(strsplit(readline("Enter the probabilities for each Y: "), " ")[[1]])
  }
  rownames(joint) <- paste("X=", x, sep = "")
  colnames(joint) <- paste("Y=", y, sep = "")
  
  if (any(joint < 0) || any(joint > 1)) {
    print("Error: probabilities must be between 0 and 1")
    return(NULL)
  }
  if (abs(sum(joint) - 1) > 0.000001) {
    print("Error: probabilities must add up to 1")
    return(NULL)
  }
  print(joint)
  
  px <- rowSums(joint)
  py <- colSums(joint)
  cat("\nMarginal of X:\n")
  print(px)
  cat("Mean of X =", sum(x * px), " Variance of X =", sum(x^2 * px) - sum(x * px)^2, "\n")
  cat("\nMarginal of Y:\n")
  print(py)
  cat("Mean of Y =", sum(y * py), " Variance of Y =", sum(y^2 * py) - sum(y * py)^2, "\n")
  
  for (i in 1:length(x)) {
    cond <- joint[i, ] / px[i]
    m <- sum(y * cond)
    v <- sum(y^2 * cond) - m^2
    cat("\nY given X =", x[i], "\n")
    print(cond)
    cat("Mean =", m, " Variance =", v, "\n")
  }
  
  for (j in 1:length(y)) {
    cond <- joint[, j] / py[j]
    m <- sum(x * cond)
    v <- sum(x^2 * cond) - m^2
    cat("\nX given Y =", y[j], "\n")
    print(cond)
    cat("Mean =", m, " Variance =", v, "\n")
  }
  
  par(mfrow = c(2, 2))
  ox <- order(x)
  oy <- order(y)
  plot(x[ox], px[ox], type = "h", main = "PDF of X", xlab = "x", ylab = "P(X = x)")
  plot(x[ox], cumsum(px[ox]), type = "s", main = "CDF of X", xlab = "x", ylab = "P(X <= x)")
  plot(y[oy], py[oy], type = "h", main = "PDF of Y", xlab = "y", ylab = "P(Y = y)")
  plot(y[oy], cumsum(py[oy]), type = "s", main = "CDF of Y", xlab = "y", ylab = "P(Y <= y)")
  par(mfrow = c(1, 1))
}


# Question 3: search engine simulation
question3 <- function() {
  p <- as.numeric(readline("Enter p (probability a site has the key phrase, e.g. 0.6): "))
  if (p <= 0 || p > 1) {
    print("p must be between 0 and 1")
    return(NULL)
  }
  
  n <- 10000
  searches <- rep(0, n)
  
  for (i in 1:n) {
    count <- 1
    while (runif(1) > p) {
      count <- count + 1
    }
    searches[i] <- count
  }
  
  pdf <- table(searches) / n
  cat("Simulated mean =", mean(searches), " (theory 1/p =", 1 / p, ")\n")
  cat("Simulated variance =", var(searches), " (theory (1-p)/p^2 =", (1 - p) / p^2, ")\n")
  
  par(mfrow = c(1, 2))
  plot(as.numeric(names(pdf)), as.numeric(pdf), type = "h",
       main = "Simulated PDF", xlab = "Number of searches", ylab = "Probability")
  

  extra <- searches[searches > 3] - 3
  cpdf <- table(extra) / length(extra)
  cat("\nConditional on X > 3 (", length(extra), "cases )\n")
  cat("Conditional mean =", mean(extra), "\n")
  cat("Conditional variance =", var(extra), "\n")
  cat("Compare with the full set: mean =", mean(searches), " variance =", var(searches), "\n")
  
  plot(as.numeric(names(cpdf)), as.numeric(cpdf), type = "h",
       main = "Conditional PDF (X-3 given X>3)", xlab = "Extra searches", ylab = "Probability")
  par(mfrow = c(1, 1))
  
  a_cond <- sum(searches == 4) / sum(searches > 3)
  a_uncond <- sum(searches == 1) / n
  b_cond <- sum(searches == 5) / sum(searches > 3)
  b_uncond <- sum(searches == 2) / n
  cat("\n(a) P(X=4 | X>3) =", a_cond, "  P(X=1) =", a_uncond, "\n")
  cat("(b) P(X=5 | X>3) =", b_cond, "  P(X=2) =", b_uncond, "\n")
  cat("The pairs are close, so the memoryless property holds.\n")
}

