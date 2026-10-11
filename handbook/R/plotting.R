plot_timeseries <- function(data, columns = c("market", "inflation"),
                            labels = c("EUR/USD reference rate (USD per EUR)", "Euro-area HICP (index level)"),
                            normalized = FALSE) {
  if(inherits(data, "aligned_timeseries")) data <- data$data
  if(length(columns) != length(labels) || !length(columns) || !all(columns %in% names(data))) stop("Specify one label for every plotted column.")
  if (!inherits(data$date, "Date") || !nrow(data) || anyNA(data$date) || is.unsorted(data$date) || anyDuplicated(data$date)) stop("Plot ordered, non-empty, unique dates.")
  if (any(format(data$date, "%d") != "01")) stop("Plot monthly data using month-start dates; aggregate daily inputs first.")
  if (!all(vapply(data[columns], is.numeric, logical(1)))) stop("Plot numeric values only.")
  if (any(vapply(data[columns], function(x) any(!is.finite(x) & !is.na(x)), logical(1)))) stop("Non-finite values must be resolved before plotting.")
  if (normalized) data <- normalize_series(data, columns)
  # Insert absent months so a line cannot silently bridge a missing observation.
  grid <- data.frame(date = seq(min(data$date), max(data$date), by = "month"))
  data <- merge(grid, data[c("date", columns)], by = "date", all.x = TRUE, sort = TRUE)
  old <- graphics::par(no.readonly = TRUE); on.exit(graphics::par(old), add = TRUE)
  graphics::par(mfrow = c(length(columns), 1), mar = c(3, 4.8, 2.5, 1), las = 1)
  for(j in seq_along(columns)) {
    values <- data[[columns[j]]]
    if (!any(is.finite(values))) stop("No finite observations to plot.")
    graphics::plot(data$date, values, type = "l", lwd = 1.8, col = c("#265b74", "#a36f31")[(j - 1) %% 2 + 1],
      xlab = "", ylab = if(normalized) "Base = 100" else "Level", main = labels[j])
    graphics::grid(col = "#e6e4de")
    graphics::lines(data$date, values, lwd = 1.8, col = c("#265b74", "#a36f31")[(j - 1) %% 2 + 1])
    missing <- !is.finite(values)
    if(any(missing)) graphics::rug(as.numeric(data$date[missing]), side = 1, col = "#b03b32", ticksize = 0.06)
  }
  invisible(data)
}
