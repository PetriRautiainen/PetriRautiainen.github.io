options(repos = c(CRAN = "https://cloud.r-project.org"), timeout = 300)
root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
stopifnot(file.exists("scripts/bootstrap.R"))
Sys.setenv(RENV_PATHS_ROOT = file.path(root, "renv/cache-root"),
           RENV_CONFIG_AUTO_SNAPSHOT = "FALSE",
           RENV_CONFIG_SANDBOX_ENABLED = "FALSE")
dir.create(".bootstrap-library", showWarnings = FALSE)
.libPaths(c(normalizePath(".bootstrap-library"), .libPaths()))
if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv", lib = ".bootstrap-library")
if (file.exists("renv.lock")) {
  renv::restore(project = root, prompt = FALSE)
} else {
  renv::init(project = root, bare = TRUE, restart = FALSE)
  renv::install(c("renv", "testthat", "knitr", "rmarkdown"))
  renv::settings$snapshot.type("all")
  renv::snapshot(type = "all", prompt = FALSE)
}
