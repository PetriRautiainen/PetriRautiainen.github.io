testthat::test_that("diagnostics expose gaps, duplicates and unordered data", {
  x <- monthly(c("2024-03-01", "2024-01-01", "2024-01-01"), c(20, 1, NA))
  check <- check_timeseries(x)
  testthat::expect_s3_class(check, "timeseries_check")
  testthat::expect_equal(check$observations, 3L)
  testthat::expect_false(check$ordered)
  testthat::expect_equal(check$duplicate_dates, as.Date("2024-01-01"))
  testthat::expect_equal(check$missing_values, 1L)
  testthat::expect_equal(check$missing_periods, as.Date("2024-02-01"))
  testthat::expect_equal(check$estimated_frequency, "monthly")
  testthat::expect_equal(check$minimum, 1)
  testthat::expect_equal(check$maximum, 20)
})

testthat::test_that("empty and zero-valued series produce safe diagnostics", {
  check <- check_timeseries(monthly(character(), numeric()))
  testthat::expect_equal(check$observations, 0L)
  testthat::expect_true(is.na(check$minimum))
  testthat::expect_equal(check$estimated_frequency, "unknown")
  check <- check_timeseries(monthly(values = c(0, 1, 2)), jump_threshold = 0.5)
  testthat::expect_equal(check$zero_denominator_dates, as.Date("2024-02-01"))
  testthat::expect_equal(check$suspicious_jumps$date, as.Date("2024-03-01"))
  testthat::expect_error(check_timeseries(monthly(), jump_threshold = 0), "positive")
  x <- monthly(); x$value[2] <- Inf
  testthat::expect_equal(check_timeseries(x)$non_finite_values, 1L)
})

testthat::test_that("weekends are separated from candidate weekday gaps", {
  x <- daily(c("2024-01-05", "2024-01-09"), c(1, 2))
  check <- check_timeseries(x, frequency = "daily")
  testthat::expect_equal(check$missing_periods, as.Date("2024-01-08"))
  testthat::expect_match(check$missing_periods_note, "holidays")
  testthat::expect_equal(length(check_timeseries(x, frequency = "daily", calendar = "calendar")$missing_periods), 3L)
})
testthat::test_that("a declared monthly singleton follows the date contract", {
  x <- monthly("2024-01-15", 1)
  testthat::expect_error(check_timeseries(x, frequency = "monthly"), "month starts")
})
