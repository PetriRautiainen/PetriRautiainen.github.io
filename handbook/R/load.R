for (file in c("sources", "cleaning", "validation", "transforms", "plotting", "example"))
  source(file.path("R", paste0(file, ".R")), local = FALSE)
