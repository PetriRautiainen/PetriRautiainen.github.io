monthly <- function(dates = c("2024-01-01", "2024-02-01", "2024-03-01"), values = seq_along(dates)) {
  out <- data.frame(date = as.Date(dates), value = as.numeric(values))
  attr(out, "frequency") <- "monthly"
  out
}
daily <- function(dates, values) {
  out <- monthly(dates, values); attr(out, "frequency") <- "daily"; out
}
