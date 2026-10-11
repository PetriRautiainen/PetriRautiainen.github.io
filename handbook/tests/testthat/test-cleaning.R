testthat::test_that("dates and values are validated rather than guessed", {
  raw <- data.frame(TIME_PERIOD = c("2024-02", "2024-01"), OBS_VALUE = c("2.5", ":"))
  out <- standardize_timeseries(raw, frequency = "monthly")
  testthat::expect_equal(out$date, as.Date(c("2024-01-01", "2024-02-01")))
  testthat::expect_true(is.na(out$value[1]))
  testthat::expect_true(attr(out, "cleaning_audit")$reordered)
  testthat::expect_error(standardize_timeseries(raw[0, ], frequency = "monthly"), "empty")
  raw$OBS_VALUE[1] <- "1,200"
  testthat::expect_error(standardize_timeseries(raw, frequency = "monthly"), "Malformed numeric")
  raw$OBS_VALUE <- c("1", "2"); raw$TIME_PERIOD <- c("2024-01", "2024-01")
  testthat::expect_error(standardize_timeseries(raw, frequency = "monthly"), "Duplicate")
  raw$TIME_PERIOD <- c("2024-13", "2024-01")
  testthat::expect_error(standardize_timeseries(raw, frequency = "monthly"), "Invalid calendar")
  raw$TIME_PERIOD <- c("2024-02-30", "2024-01-01")
  testthat::expect_error(standardize_timeseries(raw, frequency = "daily"), "Invalid calendar")
  raw$TIME_PERIOD[1] <- NA
  testthat::expect_error(standardize_timeseries(raw, frequency = "daily"), "missing dates")
})

testthat::test_that("non-finite and ambiguous inputs do not become clean data", {
  raw <- data.frame(TIME_PERIOD = c("2024-01", "2024-02"), OBS_VALUE = c("Inf", "3"))
  testthat::expect_error(standardize_timeseries(raw, frequency = "monthly"), "Malformed numeric")
  raw$OBS_VALUE <- c(Inf, 3)
  testthat::expect_error(standardize_timeseries(raw, frequency = "monthly"), "Non-finite")
  testthat::expect_error(standardize_timeseries(data.frame(x = 1)), "columns")
})
