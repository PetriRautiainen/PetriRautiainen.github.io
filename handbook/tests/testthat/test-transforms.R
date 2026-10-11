testthat::test_that("monthly aggregation preserves missing final values and excludes partial months", {
  x <- daily(c("2024-01-02", "2024-01-31", "2024-02-02", "2024-03-01"), c(1, NA, 3, 9))
  result <- aggregate_monthly(x, as_of = "2024-03-15")
  testthat::expect_equal(nrow(result), 2L)
  testthat::expect_true(is.na(result$value[1]))
  testthat::expect_equal(result$source_observation_date[1], as.Date("2024-01-31"))
  testthat::expect_equal(attr(result, "aggregation_audit")$excluded_unfinished_month_rows, 1L)
  testthat::expect_true(is.na(aggregate_monthly(x, "mean", "2024-03-15")$value[1]))
  testthat::expect_error(aggregate_monthly(x[4:1, ], as_of = "2024-04-01"), "Order")
  attr(x, "frequency") <- "weekly"
  testthat::expect_error(aggregate_monthly(x), "compatible")
})

testthat::test_that("alignment records missing periods and deliberate join losses", {
  m <- monthly(c("2024-01-01", "2024-03-01"), c(10, 12))
  i <- monthly(c("2024-01-01", "2024-02-01", "2024-03-01"), c(100, 101, 102))
  result <- align_timeseries(m, i, years = 1L, as_of = "2024-04-01")
  testthat::expect_equal(nrow(result$data), 12L)
  february <- result$data[result$data$date == as.Date("2024-02-01"), ]
  testthat::expect_false(february$market_present)
  testthat::expect_true(is.na(february$market))
  testthat::expect_equal(result$audit$imputed_values, 0L)
  inner <- align_timeseries(m, i, years = 1L, join = "inner", as_of = "2024-04-01")
  testthat::expect_equal(nrow(inner$data), 2L)
  testthat::expect_equal(length(inner$audit$dropped_by_join), 10L)
  testthat::expect_error(align_timeseries(m, monthly("2025-01-01", 1), as_of = "2025-02-01"), "No common")
  testthat::expect_error(align_timeseries(m[0, ], i), "empty")
  testthat::expect_error(align_timeseries(m, i, years = 0), "integer")
  i$observation_status <- c("A", "A", "E")
  result <- align_timeseries(m, i, years = 1L, as_of = "2024-04-01")
  testthat::expect_equal(tail(result$data$inflation_source_statuses, 1), "E")
})

testthat::test_that("normalization uses one common baseline", {
  x <- data.frame(date = as.Date(c("2024-01-01", "2024-02-01", "2024-03-01")), market = c(NA, 2, 4), inflation = c(10, 20, 22))
  result <- normalize_series(x)
  testthat::expect_equal(attr(result, "baseline_date"), as.Date("2024-02-01"))
  testthat::expect_equal(result$market, c(NA, 100, 200))
  testthat::expect_equal(result$inflation, c(50, 100, 110))
  x$market <- 0
  testthat::expect_error(normalize_series(x), "baseline")
  testthat::expect_error(normalize_series(x[3:1, ]), "ordered")
})
