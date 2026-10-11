pipeline_fingerprint <- function() {
  files <- sort(c(list.files("R", pattern = "\\.R$", full.names = TRUE), "renv.lock"))
  tools::md5sum(files)
}

build_example <- function(refresh = FALSE, offline = FALSE, as_of = "2026-10-11") {
  market_raw <- get_market_data(end = as_of, refresh = refresh, offline = offline)
  inflation_raw <- get_inflation_data(end = as_of, refresh = refresh, offline = offline)
  market <- clean_timeseries(market_raw); inflation <- clean_timeseries(inflation_raw)
  aligned <- align_timeseries(market, inflation, years = 10L, as_of = as_of)
  result <- list(market_raw = market_raw, inflation_raw = inflation_raw,
    market = market, inflation = inflation, aligned = aligned,
    pipeline_fingerprint = pipeline_fingerprint(),
    checks = list(market = check_timeseries(market), inflation = check_timeseries(inflation),
      monthly_market = check_timeseries(data.frame(date = aligned$data$date, value = aligned$data$market), frequency = "monthly"),
      monthly_inflation = check_timeseries(data.frame(date = aligned$data$date, value = aligned$data$inflation), frequency = "monthly")))
  dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(aligned$data, "data/processed/market-inflation-monthly.csv", row.names = FALSE, na = "")
  saveRDS(result, "data/processed/example.rds")
  jsonlite::write_json(list(sources = list(market = market$metadata, inflation = inflation$metadata),
                           alignment = aligned$audit, pipeline_fingerprint = as.list(result$pipeline_fingerprint),
                           observation_status_counts = list(market = as.list(table(market$data$observation_status)), inflation = as.list(table(inflation$data$observation_status))),
                           session = capture.output(sessionInfo())),
    "data/processed/audit.json", auto_unbox = TRUE, pretty = TRUE, na = "null")
  result
}

load_example <- function() {
  if (!file.exists("data/processed/example.rds")) stop("Run Rscript scripts/run-example.R before rendering. Rendering never downloads data.")
  result <- readRDS("data/processed/example.rds")
  if (!identical(result$pipeline_fingerprint, pipeline_fingerprint())) stop("Pipeline or lockfile changed: rebuild the example before rendering.")
  for (series in c("market", "inflation")) {
    metadata <- result[[series]]$metadata
    raw_path <- file.path("data/raw", metadata$raw_file)
    if (!file.exists(raw_path) || !identical(unname(tools::md5sum(raw_path)), metadata$checksum_md5))
      stop("Retained raw snapshot is missing or changed: rebuild the example before rendering.")
  }
  result
}
