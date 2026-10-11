# A small canonical table: date (Date) and value (numeric). No imputation.
standardize_timeseries <- function(data, date_col = "TIME_PERIOD",
                                   value_col = "OBS_VALUE", frequency = c("daily", "monthly")) {
  frequency <- match.arg(frequency)
  if (!is.data.frame(data) || !all(c(date_col, value_col) %in% names(data)))
    stop("Expected a data frame with the requested date and value columns.")
  if (!nrow(data)) stop("Cannot standardize an empty dataset.")
  dates <- data[[date_col]]
  if (!inherits(dates, "Date")) {
    text <- as.character(dates)
    pattern <- if (frequency == "monthly") "^[0-9]{4}-[0-9]{2}$" else "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"
    if (anyNA(text) || any(!grepl(pattern, text))) stop("Malformed or missing dates.")
    date_text <- if (frequency == "monthly") paste0(text, "-01") else text
    dates <- as.Date(date_text, format = "%Y-%m-%d")
    if (anyNA(dates) || any(format(dates, "%Y-%m-%d") != date_text)) stop("Invalid calendar dates.")
  }
  if (anyNA(dates)) stop("Missing dates are not allowed.")
  if (frequency == "monthly" && any(format(dates, "%d") != "01"))
    stop("Monthly dates must denote the first day of the observation month.")
  values <- data[[value_col]]
  if (!is.numeric(values)) {
    text <- trimws(as.character(values))
    missing <- is.na(text) | text %in% c("", ":", "NA", ".")
    valid <- grepl("^[+-]?([0-9]+\\.?[0-9]*|\\.[0-9]+)([eE][+-]?[0-9]+)?$", text)
    if (any(!missing & !valid)) stop("Malformed numeric data; specify decimal and thousands conventions explicitly.")
    values <- rep(NA_real_, length(text))
    values[!missing] <- as.numeric(text[!missing])
  }
  if (any(!is.finite(values) & !is.na(values))) stop("Non-finite numeric values.")
  if (anyDuplicated(dates)) stop("Duplicate dates: resolve the source or aggregation rule explicitly.")
  ordered <- !is.unsorted(dates)
  order <- order(dates)
  out <- data.frame(date = dates[order], value = values[order])
  if ("OBS_STATUS" %in% names(data)) out$observation_status <- data$OBS_STATUS[order]
  attr(out, "frequency") <- frequency
  attr(out, "cleaning_audit") <- list(input_rows = nrow(data), output_rows = nrow(out),
                                      reordered = !ordered, imputed_values = 0L,
                                      missing_values_preserved = sum(is.na(values)))
  out
}

clean_timeseries <- function(download) {
  if (!inherits(download, "handbook_download")) stop("Expected a handbook_download.")
  data <- standardize_timeseries(download$data, frequency = download$metadata$frequency)
  metadata <- download$metadata
  metadata$cleaning <- attr(data, "cleaning_audit")
  structure(list(data = data, metadata = metadata), class = "handbook_series")
}

series_data <- function(x) if (inherits(x, "handbook_series")) x$data else x
