check_timeseries <- function(x, frequency = c("auto", "daily", "monthly"),
                             calendar = c("business", "calendar"), jump_threshold = 0.1) {
  frequency <- match.arg(frequency); calendar <- match.arg(calendar)
  data <- series_data(x)
  if (!is.data.frame(data) || !all(c("date", "value") %in% names(data))) stop("Expected date and value columns.")
  if (!inherits(data$date, "Date")) stop("date must be a Date column.")
  if (!is.numeric(data$value)) stop("value must be numeric.")
  if (anyNA(data$date)) stop("Missing dates cannot be diagnosed as periods.")
  if (length(jump_threshold) != 1 || !is.finite(jump_threshold) || jump_threshold <= 0) stop("jump_threshold must be positive.")
  n <- nrow(data); dates <- sort(unique(data$date))
  inferred <- "unknown"
  if (length(dates) >= 2) {
    month_id <- as.integer(format(dates, "%Y")) * 12L + as.integer(format(dates, "%m"))
    gaps <- as.numeric(diff(dates))
    if (all(format(dates, "%d") == "01") && all(diff(month_id) >= 1) && stats::median(gaps) >= 27)
      inferred <- "monthly"
    else if (stats::median(gaps) <= 4) inferred <- "daily"
  }
  used <- if (frequency == "auto") inferred else frequency
  if (used == "monthly" && any(format(dates, "%d") != "01")) stop("Monthly dates must use month starts.")
  expected <- as.Date(character())
  if (length(dates) >= 2 && used %in% c("daily", "monthly")) {
    if (used == "monthly") {
      expected <- seq(min(dates), max(dates), by = "month")
    } else {
      expected <- seq(min(dates), max(dates), by = "day")
      if (calendar == "business") expected <- expected[as.POSIXlt(expected)$wday %in% 1:5]
    }
  }
  missing_periods <- expected[!expected %in% dates]
  sorted <- data[order(data$date), , drop = FALSE]
  delta <- rep(NA_real_, n)
  if (n > 1) {
    previous <- head(sorted$value, -1)
    delta[-1] <- ifelse(is.finite(previous) & previous != 0, diff(sorted$value) / abs(previous), NA_real_)
  }
  jumps <- data.frame(date = sorted$date[which(is.finite(delta) & abs(delta) > jump_threshold)],
                      relative_change = delta[which(is.finite(delta) & abs(delta) > jump_threshold)])
  finite <- data$value[is.finite(data$value)]
  structure(list(start_date = if(n) min(data$date) else as.Date(NA),
    end_date = if(n) max(data$date) else as.Date(NA), observations = n,
    estimated_frequency = inferred, expected_frequency = used,
    ordered = !is.unsorted(data$date), duplicate_dates = unique(data$date[duplicated(data$date)]),
    missing_values = sum(is.na(data$value)), non_finite_values = sum(!is.finite(data$value) & !is.na(data$value)),
    missing_periods = missing_periods,
    missing_periods_note = if(used == "daily" && calendar == "business") "Weekday candidates only; provider holidays are not known." else "Gaps within observed bounds only; no claim about the requested boundaries.",
    minimum = if(length(finite)) min(finite) else NA_real_,
    maximum = if(length(finite)) max(finite) else NA_real_,
    suspicious_jumps = jumps, jump_threshold = jump_threshold,
    zero_denominator_dates = if(n > 1) sorted$date[-1][which(head(sorted$value, -1) == 0)] else as.Date(character())),
    class = "timeseries_check")
}

diagnostics_table <- function(check) {
  data.frame(metric = c("Start", "End", "Observations", "Estimated frequency", "Ordered", "Duplicate dates", "Missing values", "Non-finite values", "Missing-period candidates", "Minimum", "Maximum", "Flagged changes"),
    value = as.character(c(as.character(check$start_date), as.character(check$end_date), check$observations,
      check$estimated_frequency, check$ordered, length(check$duplicate_dates), check$missing_values,
      check$non_finite_values, length(check$missing_periods), check$minimum, check$maximum, nrow(check$suspicious_jumps))))
}
