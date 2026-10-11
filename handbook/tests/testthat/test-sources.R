testthat::test_that("source adapters reject broken schemas and wrong keys", {
  spec <- source_catalog()$market
  path <- tempfile(fileext = ".csv"); on.exit(unlink(path))
  utils::write.csv(data.frame(date = "2024-01-01", value = 1), path, row.names = FALSE)
  testthat::expect_error(read_ecb_csv(path, spec), "schema")
  x <- data.frame(KEY = "EXR.WRONG", TIME_PERIOD = "2024-01-01", OBS_VALUE = "1")
  utils::write.csv(x, path, row.names = FALSE)
  testthat::expect_error(read_ecb_csv(path, spec), "key")
  x$KEY <- "EXR.D.USD.EUR.SP00.A"; x$UNIT_MULT <- "3"
  utils::write.csv(x, path, row.names = FALSE)
  testthat::expect_error(read_ecb_csv(path, spec), "scaling")
  testthat::expect_error(get_market_data(cache_dir = tempdir(), offline = TRUE, start = "1980-01-01"), "cached")
})

testthat::test_that("cached replay checks raw integrity, metadata and index base", {
  cache <- tempfile(); dir.create(cache); on.exit(unlink(cache, recursive = TRUE))
  path <- file.path(cache, "market_2015-01-01_2026-10-11.csv")
  manifest <- sub("\\.csv$", ".rds", path)
  x <- data.frame(KEY = "EXR.D.USD.EUR.SP00.A", TIME_PERIOD = "2024-01-02", OBS_VALUE = "1.1", UNIT_MULT = "0")
  utils::write.csv(x, path, row.names = FALSE)
  metadata <- list(request_url = paste0("https://data-api.ecb.europa.eu/service/data/EXR/D.USD.EUR.SP00.A?",
    "startPeriod=2015-01-01&endPeriod=2026-10-11&format=csvdata"), checksum_md5 = unname(tools::md5sum(path)))
  saveRDS(metadata, manifest)
  testthat::expect_s3_class(get_market_data(cache_dir = cache, offline = TRUE), "handbook_download")
  metadata$request_url <- "wrong"; saveRDS(metadata, manifest)
  testthat::expect_error(get_market_data(cache_dir = cache, offline = TRUE), "metadata mismatch")
  write("changed", path, append = TRUE)
  testthat::expect_error(get_market_data(cache_dir = cache, offline = TRUE), "checksum")
  x <- rbind(x, x); x$UNIT_INDEX_BASE <- c("2015 = 100", "2025 = 100")
  utils::write.csv(x, path, row.names = FALSE)
  testthat::expect_error(read_ecb_csv(path, source_catalog()$market), "Units vary")
})
