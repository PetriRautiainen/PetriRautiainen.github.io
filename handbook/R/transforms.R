aggregate_monthly <- function(x, method = c("last", "mean"), as_of = "2026-10-11") {
  method <- match.arg(method)
  data <- series_data(x)
  frequency <- if(inherits(x, "handbook_series")) x$metadata$frequency else attr(data, "frequency")
  if (length(frequency) != 1 || !frequency %in% c("daily", "monthly")) stop("Declare a compatible daily or monthly frequency.")
  check <- check_timeseries(data, frequency = frequency)
  if (!nrow(data)) stop("Cannot aggregate an empty dataset.")
  if (length(check$duplicate_dates)) stop("Duplicate dates must be resolved before aggregation.")
  if (!check$ordered) stop("Order dates before aggregation.")
  if (check$non_finite_values) stop("Non-finite values cannot be aggregated.")
  cutoff <- as.Date(format(as.Date(as_of), "%Y-%m-01"))
  if (is.na(cutoff)) stop("Invalid as_of date.")
  complete <- data[data$date < cutoff, , drop = FALSE]
  if (!nrow(complete)) stop("No observations in completed calendar months.")
  groups <- split(seq_len(nrow(complete)), format(complete$date, "%Y-%m"))
  rows <- lapply(names(groups), function(month) {
    group <- complete[groups[[month]], , drop = FALSE]
    if (frequency == "monthly" && nrow(group) != 1) stop("Multiple observations per monthly period.")
    value <- if(frequency == "monthly" || method == "last") tail(group$value, 1) else mean(group$value)
    data.frame(date = as.Date(paste0(month, "-01")), value = value,
      source_observation_date = tail(group$date, 1), source_observations = nrow(group),
      missing_source_values = sum(is.na(group$value)),
      source_statuses = if("observation_status" %in% names(group)) paste(sort(unique(group$observation_status)), collapse = ";") else NA_character_)
  })
  out <- do.call(rbind, rows); rownames(out) <- NULL
  attr(out, "frequency") <- "monthly"
  attr(out, "aggregation_audit") <- list(input_rows = nrow(data), excluded_unfinished_month_rows = nrow(data) - nrow(complete),
    output_months = nrow(out), method = if(frequency == "monthly") "already monthly" else method,
    missing_value_policy = "preserve NA; last means last recorded observation, never last non-missing", as_of = as.character(as.Date(as_of)))
  out
}

align_timeseries <- function(market, inflation, years = 10L, market_method = c("last", "mean"),
                             join = c("full", "inner", "left"), as_of = "2026-10-11") {
  market_method <- match.arg(market_method); join <- match.arg(join)
  if(length(years) != 1 || is.na(years) || years != as.integer(years) || years < 1 || years > 100) stop("years must be an integer from 1 to 100.")
  m <- aggregate_monthly(market, method = market_method, as_of = as_of)
  i <- aggregate_monthly(inflation, as_of = as_of)
  joint_finite <- intersect(m$date[is.finite(m$value)], i$date[is.finite(i$value)])
  if (!length(joint_finite)) stop("No common usable monthly observations.")
  end <- as.Date(max(joint_finite), origin = "1970-01-01")
  window <- rev(seq(end, by = "-1 month", length.out = years * 12L))
  start <- min(window)
  mi <- match(window, m$date); ii <- match(window, i$date)
  out <- data.frame(date = window, market = m$value[mi], inflation = i$value[ii],
    market_present = !is.na(mi), inflation_present = !is.na(ii),
    market_observation_date = m$source_observation_date[mi],
    market_observations = m$source_observations[mi],
    market_missing_values = m$missing_source_values[mi],
    market_source_statuses = m$source_statuses[mi], inflation_source_statuses = i$source_statuses[ii])
  retain <- switch(join, full = rep(TRUE, nrow(out)), inner = out$market_present & out$inflation_present, left = out$market_present)
  dropped <- out$date[!retain]
  out <- out[retain, , drop = FALSE]; rownames(out) <- NULL
  audit <- list(start = as.character(start), end = as.character(end), requested_months = years * 12L,
    output_rows = nrow(out), join = join, dropped_by_join = as.character(dropped),
    market_aggregation = attr(m, "aggregation_audit"), inflation_aggregation = attr(i, "aggregation_audit"),
    market_months_outside_window = sum(m$date < start | m$date > end),
    inflation_months_outside_window = sum(i$date < start | i$date > end),
    absent_market_months = as.character(window[is.na(mi)]), absent_inflation_months = as.character(window[is.na(ii)]),
    imputed_values = 0L, alignment = "observation month, not release date; unsuitable for point-in-time backtests")
  structure(list(data = out, audit = audit, monthly_market = m, monthly_inflation = i), class = "aligned_timeseries")
}

normalize_series <- function(data, columns = c("market", "inflation")) {
  if (!all(c("date", columns) %in% names(data)) || !all(vapply(data[columns], is.numeric, logical(1)))) stop("Expected numeric series columns.")
  if (!inherits(data$date, "Date") || anyNA(data$date) || is.unsorted(data$date) || anyDuplicated(data$date)) stop("Normalize ordered, unique Date values.")
  usable <- which(Reduce(`&`, lapply(data[columns], function(v) is.finite(v) & v != 0)))
  if (!length(usable)) stop("No common finite non-zero normalization baseline.")
  baseline <- usable[1]
  out <- data[c("date", columns)]
  for(column in columns) out[[column]] <- 100 * data[[column]] / data[[column]][baseline]
  attr(out, "baseline_date") <- data$date[baseline]
  out
}
