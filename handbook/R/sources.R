source_catalog <- function() {
  list(
    market = list(flow = "EXR", key = "D.USD.EUR.SP00.A", frequency = "daily",
      label = "ECB EUR/USD reference exchange rate", unit = "USD per EUR",
      originator = "European Central Bank", interpretation = "Reference spot exchange rate; not an equity index or total-return investment.",
      documentation = "https://data.ecb.europa.eu/data/datasets/EXR/EXR.D.USD.EUR.SP00.A",
      terms = "https://www.ecb.europa.eu/stats/ecb_statistics/governance_and_quality_framework/html/usage_policy.en.html"),
    inflation = list(flow = "HICP", key = "M.U2.N.000000.4D0.INX", frequency = "monthly",
      label = "Euro-area all-items HICP, unadjusted", unit = "Index (provider's reference base)",
      originator = "Eurostat, distributed by ECB", interpretation = "Consumer price index level; not an annual inflation rate. Euro area has changing composition.",
      documentation = "https://data.ecb.europa.eu/data/datasets/HICP/HICP.M.U2.N.000000.4D0.INX",
      terms = "https://ec.europa.eu/eurostat/help/copyright-notice")
  )
}

read_ecb_csv <- function(path, spec) {
  data <- utils::read.csv(path, colClasses = "character", na.strings = NULL,
                          check.names = FALSE, fileEncoding = "UTF-8")
  needed <- c("KEY", "TIME_PERIOD", "OBS_VALUE")
  if (!all(needed %in% names(data)) || !nrow(data)) stop("ECB response is empty or has an unexpected CSV schema.")
  if (!identical(unique(data$KEY), paste(spec$flow, spec$key, sep = ".")))
    stop("Unexpected series key in the ECB response.")
  for (column in intersect(c("UNIT", "UNIT_MULT", "UNIT_INDEX_BASE", "BASE_PER"), names(data))) {
    if (length(unique(data[[column]])) != 1L) stop("Units vary within the response; review before combining.")
  }
  if ("UNIT_MULT" %in% names(data) && any(data$UNIT_MULT != "0"))
    stop("Non-zero unit multiplier: add and document explicit scaling first.")
  data
}

get_ecb_data <- function(kind, start = "2015-01-01", end = "2026-10-11",
                         cache_dir = "data/raw", refresh = FALSE, offline = FALSE) {
  spec <- source_catalog()[[kind]]
  if (is.null(spec)) stop("Unknown source.")
  start <- as.Date(start); end <- as.Date(end)
  if (anyNA(c(start, end)) || start > end) stop("Invalid request date range.")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  stem <- paste(kind, start, end, sep = "_")
  path <- file.path(cache_dir, paste0(stem, ".csv"))
  manifest_path <- file.path(cache_dir, paste0(stem, ".rds"))
  url <- paste0("https://data-api.ecb.europa.eu/service/data/", spec$flow, "/", spec$key,
                "?startPeriod=", start, "&endPeriod=", end, "&format=csvdata")
  if (offline && refresh) stop("offline and refresh cannot both be TRUE.")
  cached <- file.exists(path) && file.exists(manifest_path)
  if (offline && !cached) stop("No complete cached snapshot. Run the example online once.")
  if (!cached || refresh) {
    tmp <- tempfile("ecb-response-", tmpdir = cache_dir, fileext = ".csv")
    on.exit(unlink(tmp), add = TRUE)
    old_timeout <- getOption("timeout")
    options(timeout = 60); on.exit(options(timeout = old_timeout), add = TRUE)
    last_error <- NULL
    for (attempt in 1:3) {
      success <- tryCatch({
        code <- utils::download.file(url, tmp, mode = "wb", quiet = TRUE, method = "libcurl")
        if (code != 0L) stop("Download failed.")
        read_ecb_csv(tmp, spec)
        TRUE
      }, error = function(e) { last_error <<- conditionMessage(e); FALSE })
      if (success) break
      if (attempt < 3) Sys.sleep(attempt)
    }
    if (!success) stop("ECB download failed; no silent fallback to old data: ", last_error)
    metadata <- c(spec, list(request_url = url, requested_start = as.character(start),
      requested_end = as.character(end), retrieved_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
      checksum_md5 = unname(tools::md5sum(tmp)), vintage = "latest available at retrieval; not point-in-time",
      publication_date = "not supplied as an observation-level release date by this CSV"))
    if (!file.copy(tmp, path, overwrite = TRUE)) stop("Cannot save the raw snapshot.")
    saveRDS(metadata, manifest_path)
  }
  metadata <- readRDS(manifest_path)
  if (!identical(unname(tools::md5sum(path)), metadata$checksum_md5)) stop("Raw snapshot checksum mismatch.")
  if (!identical(metadata$request_url, url)) stop("Cached request metadata mismatch.")
  data <- read_ecb_csv(path, spec)
  metadata$raw_file <- basename(path)
  metadata$rows <- nrow(data)
  metadata$provider_attributes <- lapply(data[intersect(c("TITLE", "TITLE_COMPL", "UNIT", "UNIT_MULT", "UNIT_INDEX_BASE", "BASE_PER", "TIME_FORMAT", "COLLECTION", "DECIMALS"), names(data))], unique)
  structure(list(data = data, metadata = metadata), class = "handbook_download")
}

get_market_data <- function(...) get_ecb_data("market", ...)
get_inflation_data <- function(...) get_ecb_data("inflation", ...)
