# Probability & Probability Distributions Assignment

**Course:** Probability & Probability Distributions
**Language:** R (run in RStudio)

## Repository contents

| File / Folder | Description |
|---|---|
| `probability_assignment.R` | R code for Section I (items 1 to 3) |
| `outputs/` | Console output screenshots for each test run |
| `plots/` | PDF and CDF plots produced by the programs |
| `README.md` | This file |

## How to run

1. Open `probability_assignment.R` in RStudio and click **Source**.
2. In the **Console**, call one of the functions below and type the inputs when prompted. Separate numbers with spaces.

| Function | Item |
|---|---|
| `question1()` | Item 1: probability a product is defective |
| `univariate()` | Item 2: univariate discrete random variable |
| `bivariate()` | Item 2: bivariate discrete random variable |
| `question3()` | Item 3: search engine simulation |

## Item 1: Defective product probability

**Method:** Law of total probability. If factory *i* produces a share x<sub>i</sub> of the product and has defective rate y<sub>i</sub>, then

P(defective) = x<sub>1</sub>y<sub>1</sub> + x<sub>2</sub>y<sub>2</sub> + x<sub>3</sub>y<sub>3</sub>

**Input checks:** each x<sub>i</sub> must be in [0.10, 0.40] (10% to 40%) and sum to 1. Each y<sub>i</sub> must be in [0.01, 0.05] (1% to 5%) and sum to 0.12. The program prompts again until the input is valid, and accepts decimals or percentages.

**Test run:** x = (0.3, 0.4, 0.3), y = (0.03, 0.04, 0.05) gives P(defective) = 0.04.

**Interpretation:** About 4% of all products are defective. The result is a weighted average of the factory defect rates, weighted by each factory's share of production.

## Item 2: Discrete distributions front end

### Univariate
The user enters the values of X and their probabilities. The program checks that each probability is in [0, 1] and that they sum to 1, then calculates:

- Mean: E(X) = Σ x·p(x)
- Variance: Var(X) = Σ x²·p(x) − [E(X)]²

It also plots the PDF and CDF.

**Test run:** X = 0, 1, 2, 3 with p = 0.1, 0.4, 0.3, 0.2 gives mean = 1.6 and variance = 0.84.

**Interpretation:** The mean of 1.6 is the long-run average value of X, and it sits near the most likely values (1 and 2). The variance of 0.84 (standard deviation about 0.92) shows how spread out X is around that mean. The CDF is a step function that rises at each value of X and reaches 1 at the largest value, which confirms the probabilities sum to 1.

### Bivariate
The user enters the values of X and Y and the joint probability table. After the same validity checks, the program outputs:

- the marginal distributions of X and Y (mean and variance of each),
- all conditional distributions P(Y | X = x) and P(X | Y = y) (mean and variance of each),
- PDF and CDF plots of the marginals.

**Test run:** X = 1, 2 and Y = 1, 2, 3 with joint rows (0.1, 0.2, 0.1) and (0.2, 0.3, 0.1):

- Marginal of X: (0.4, 0.6), mean 1.6, variance 0.24
- Marginal of Y: (0.3, 0.5, 0.2), mean 1.9, variance 0.49
- Y given X = 1: (0.25, 0.5, 0.25), mean 2, variance 0.5

**Interpretation:** The marginals describe X and Y on their own, ignoring the other variable. The conditionals describe one variable once the other is known. Here the conditional distribution of Y changes with X (given X = 1, Y has mean 2, but the overall mean of Y is 1.9), so X and Y are not independent. If they were independent, every conditional distribution would equal the marginal.

## Item 3: Search engine simulation

**Setup:** X is the number of searches until the key phrase is found. Each site contains the phrase with probability p (test value p = 0.6). The program simulates 10,000 searches, so X follows a geometric distribution with mean 1/p and variance (1 − p)/p².

**Outputs:**
- Simulated PDF plot, with its mean and variance
- Simulated conditional distribution given three failed searches (X > 3), shown as X − 3, with its mean and variance
- Estimates for the memoryless property check:
  - (a) P(X = 4 | X > 3) compared with P(X = 1)
  - (b) P(X = 5 | X > 3) compared with P(X = 2)

**Results (p = 0.6, 10,000 simulated searches):**

| Quantity | Simulated | Theory |
|---|---|---|
| Mean of X | 1.6776 | 1.667 |
| Variance of X | 1.1610 | 1.111 |
| Mean of conditional distribution | 1.6985 | 1.667 |
| Variance of conditional distribution | 1.1034 | 1.111 |
| P(X=4 \| X>3) vs P(X=1) | 0.5735 vs 0.6003 | 0.6 |
| P(X=5 \| X>3) vs P(X=2) | 0.2632 vs 0.2373 | 0.24 |

Console output from this run:

```
Simulated mean = 1.6776  (theory 1/p = 1.666667 )
Simulated variance = 1.160974  (theory (1-p)/p^2 = 1.111111 )

Conditional on X > 3 ( 680 cases )
Conditional mean = 1.698529
Conditional variance = 1.103385
Compare with the full set: mean = 1.6776  variance = 1.160974

(a) P(X=4 | X>3) = 0.5735294   P(X=1) = 0.6003
(b) P(X=5 | X>3) = 0.2632353   P(X=2) = 0.2373
```

**Interpretation:** The simulated mean (1.6776) and variance (1.1610) are close to the theoretical geometric values of 1/p = 1.667 and (1 − p)/p² = 1.111, so the simulation is working. Given that three searches failed (680 of the 10,000 runs), the extra searches needed have mean 1.6985 and variance 1.1034, almost the same as the full set (1.6776 and 1.1610). The estimates also match: P(X=4 | X>3) = 0.5735 is close to P(X=1) = 0.6003, and P(X=5 | X>3) = 0.2632 is close to P(X=2) = 0.2373. This supports the memoryless property of the geometric distribution: past failures do not change the chance of success on the next search. The small differences are simulation randomness, and they are largest in the conditional estimates because those use only 680 runs instead of 10,000.

