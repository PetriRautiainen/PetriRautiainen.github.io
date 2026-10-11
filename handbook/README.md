# The Analyst's Handbook

An unpublished, self-contained English Quarto book: **Part I — Building Reliable Data**. The Finnish website is a separate project in the parent directory. Its root render excludes this entire directory, including data and R dependencies. The existing Pages workflow is unchanged.

## Requirements and first run

Tested with **R 4.4.1** and **Quarto 1.9.38**. Install these separately and put `Rscript` and `quarto` on PATH. `renv.lock` pins the R packages; it does not install R or Quarto. On another operating system, restoring packages may require that system's normal R compilation tools.

Run all commands **from `handbook/`**:

```sh
Rscript --vanilla scripts/bootstrap.R
Rscript scripts/run-tests.R
Rscript scripts/run-example.R
quarto render
quarto preview
```

The bootstrap restores the lockfile into the handbook's private library. The first restore contacts CRAN, and the first example run contacts the public ECB API. No API keys or private credentials are used. For subsequent sessions `.Rprofile` activates the handbook environment automatically; do not use `--vanilla` for the example, tests or render. To inspect dependency consistency: `Rscript -e 'renv::status()'`.

`renv` package caching is disabled to keep complete package files in the private library. Its optional base-package sandbox is disabled; the library still consists of the handbook's packages and the installed R distribution. This avoids expensive sandbox activation in the local Windows environment. No existing website dependencies are changed.

## Replay and refresh

```sh
Rscript scripts/run-example.R --offline
quarto render
```

Offline replay needs both raw CSVs and their RDS manifests in `data/raw/`. These are kept locally and ignored by Git. On a fresh checkout, run the example online once or restore an archived snapshot. After that, both tests and rendering work without contacting a data provider. Rendering checks the raw checksums and R code/lockfile fingerprint before using the processed example. Changes require rebuilding the example explicitly.

To obtain a new provider vintage, run `Rscript scripts/run-example.R --refresh`. **Archive the old `data/raw/` and `data/processed/` first** if their vintage matters: refresh replaces the two named snapshots. A failed refresh reports an error and never silently falls back to the old values. Latest-vintage replay is not a historical point-in-time backtest.

The milestone's request end is fixed at `2026-10-11`; the function arguments allow another explicit end/as-of date. To change the book's worked example, change the default `as_of` in `R/example.R` and the corresponding documented date in Chapters 1, 2 and 4, then rebuild. An API request end does not imply that data exist to that date.

## Architecture

| Location | Responsibility |
|---|---|
| `index.qmd`, `chapters/01-…06-*.qmd` | Introduction and six executable chapters |
| `R/sources.R` | Exact ECB series requests, response checks, unchanged cache, metadata |
| `R/cleaning.R` | Strict date/numeric parsing and a canonical `date`/`value` table |
| `R/validation.R` | Structured `check_timeseries()` diagnostics |
| `R/transforms.R` | Completed-month aggregation, alignment audit, common normalization |
| `R/plotting.R` | Monthly validation panels with explicit gaps |
| `R/example.R`, `R/load.R` | End-to-end example, freshness checks and module loading |
| `tests/testthat/` | Offline tests of meaningful data failure modes |
| `renv.lock`, `.Rprofile`, `renv/` | Handbook-only package environment |
| `data/raw/`, `data/processed/`, `_book/` | Local snapshots, derived results and rendered HTML |

API entry points are `get_market_data()`, `get_inflation_data()`, `check_timeseries()`, `align_timeseries()` and `plot_timeseries()`. Source `R/load.R` to use them. Diagnostics report problems; standardization and aggregation reject inputs whose interpretation is unresolved. The plotting API accepts monthly month-start dates; aggregate daily input explicitly first.

## Worked example and provenance

- Market: [ECB EUR/USD reference exchange rate](https://data.ecb.europa.eu/data/datasets/EXR/EXR.D.USD.EUR.SP00.A), `EXR.D.USD.EUR.SP00.A`, daily USD per EUR. This is a market reference price, not an equity index or total-return asset.
- Inflation: [Eurostat all-items euro-area HICP via ECB](https://data.ecb.europa.eu/data/datasets/HICP/HICP.M.U2.N.000000.4D0.INX), `HICP.M.U2.N.000000.4D0.INX`, monthly, unadjusted, changing euro-area composition. The retained response's `UNIT_INDEX_BASE` is `2025 = 100`.
- These sources provide documented public CSV APIs without credentials. ECB-originated and Eurostat statistics have public reuse terms; retain attribution and label transformed results. See [ECB conditions](https://www.ecb.europa.eu/stats/ecb_statistics/governance_and_quality_framework/html/usage_policy.en.html) and [Eurostat conditions](https://ec.europa.eu/eurostat/help/copyright-notice). Third-party series require their own rights review.

Acquisition starts in January 2015. The final table covers the last 120 common completed months with finite endpoint values: **October 2016–September 2026** in the retained milestone snapshot. Currency values use the last recorded observation in each month, preserving an NA final value. HICP stays monthly. No forward filling or interpolation occurs. The default full grid exposes absent months; deliberate inner/left join losses are recorded.

The final HICP row has provider status `E` (estimated). It is retained and visible, rather than treated as final. Observation statuses, original currency observation dates, record counts and missing-value counts survive alignment. Whether to exclude estimates is a future analytical policy decision.

Inspect these outputs:

- `market-inflation-monthly.csv`: 120 monthly rows, source-presence flags and coverage/status fields.
- `example.rds`: raw/cleaned series, aligned output and diagnostic objects.
- `audit.json`: exact URLs, UTC retrieval times, checksums, attributes, transformation audit, status counts, source-code/lockfile fingerprint and R session information.
- `validation.png`, `normalized.png`: separate panels for unlike units; normalization uses one common baseline.
- `_book/index.html`: rendered book, with collapsed executable R code and derived figures.

The source snapshots have 3,014 currency rows and 141 HICP rows. The pipeline excludes seven currency observations in unfinished October 2026 and selects the final 120 completed months. Monthly output contains no missing values, duplicate dates or missing months in this snapshot. This verifies those properties; it does not prove economic suitability for a later investment question.

## Verification and limits

Tests cover malformed and impossible dates, ambiguous numeric text, duplicates, empty/unsorted tables, non-finite values, missing periods, incompatible frequencies, partial months, join losses, common-baseline normalization, cache corruption, status preservation, plotting gaps and stale processed output. Tests never download data.

Daily gap detection uses weekdays, not the ECB holiday calendar. Frequency estimation is heuristic. Jump flags use an explicit adjacent-change threshold, not an outlier model. Both sources are latest available at retrieval; observation-month alignment does not reconstruct release timing. Part II, investment conclusions and book publishing are outside this milestone.

To verify the original website separately, run `quarto render` **from the repository root**. The root build must contain no handbook files, chapter search entries, raw data or R libraries. Do not publish, push, merge or change Pages settings as part of this handbook milestone.

The local Codex Windows filesystem restriction can make R's `file.access()` report unreadable package files even when reads work; this produced a false `renv::status()` warning. Dependency consistency was verified successfully outside that restricted check. Normal local R and Quarto installations do not need the earlier website check tool's cache adaptation.
