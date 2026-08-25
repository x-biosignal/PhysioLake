# The non-SummarizedExperiment physio types (MultiRatePhysioExperiment,
# PhysioLongitudinal, AnalysisResult) are not intercepted by OmicsLake's generic
# SEAdapter, so OmicsLake's default object storage serializes them with full
# fidelity -- no bespoke storage adapter is required. These tests pin that
# guarantee, including that nested PhysioExperiment provenance survives.

test_that("MultiRatePhysioExperiment round-trips with nested PE provenance intact", {
  skip_if_not_installed("OmicsLake")
  skip_if_not_installed("PhysioPreprocess")

  set.seed(1)
  m <- matrix(rnorm(400 * 3), 400, 3); colnames(m) <- paste0("C", 1:3)
  pe <- PhysioExperiment(
    assays = S4Vectors::SimpleList(raw = m),
    colData = S4Vectors::DataFrame(name = colnames(m), type = "eeg"),
    samplingRate = 200)
  pe <- PhysioPreprocess::butterworthFilter(pe, low = 1, high = 40)
  h_pe <- PhysioCore::provenanceHash(pe)

  mr <- MultiRatePhysioExperiment(streams = list(eeg = pe))
  lake <- new_test_lake()
  lake$put("mr", mr)
  mr2 <- lake$get("mr")

  expect_s4_class(mr2, "MultiRatePhysioExperiment")
  pe2 <- mr2@streams[["eeg"]]
  expect_s4_class(pe2, "PhysioExperiment")
  expect_equal(PhysioCore::samplingRate(pe2), 200)
  expect_identical(PhysioCore::provenanceHash(pe2), h_pe)   # nested provenance intact
})

test_that("AnalysisResult round-trips via default serialization", {
  skip_if_not_installed("OmicsLake")
  ar <- AnalysisResult(type = "demo",
                       result = list(mean_hr = 72.03, sdnn = 1.4))
  lake <- new_test_lake()
  lake$put("ar", ar)
  ar2 <- lake$get("ar")
  expect_s4_class(ar2, "AnalysisResult")
  expect_equal(ar2@result$mean_hr, 72.03)
})

test_that("PhysioLongitudinal round-trips with nested session provenance intact", {
  skip_if_not_installed("OmicsLake")
  skip_if_not_installed("PhysioPreprocess")

  mk <- function(sr, seed) {
    set.seed(seed)
    m <- matrix(rnorm(400 * 3), 400, 3); colnames(m) <- paste0("C", 1:3)
    PhysioPreprocess::butterworthFilter(
      PhysioExperiment(S4Vectors::SimpleList(raw = m),
                       colData = S4Vectors::DataFrame(name = colnames(m), type = "eeg"),
                       samplingRate = sr),
      low = 1, high = 40)
  }
  b <- mk(250, 1); d <- mk(500, 2)
  h_b <- PhysioCore::provenanceHash(b)

  pl <- PhysioLongitudinal(
    baseline = b, discharge = d,
    design = S4Vectors::DataFrame(
      session_id = c("baseline", "discharge"),
      visit_label = c("baseline", "discharge"),
      days_from_baseline = c(0, 42)),
    subject = S4Vectors::DataFrame(id = "sub-01", dx = "stroke", side = "L"))

  lake <- new_test_lake()
  lake$put("pl", pl)
  pl2 <- lake$get("pl")

  expect_s4_class(pl2, "PhysioLongitudinal")
  expect_identical(names(pl2@sessions), c("baseline", "discharge"))  # chronological
  expect_s4_class(pl2@sessions[["baseline"]], "PhysioExperiment")
  expect_equal(PhysioCore::samplingRate(pl2@sessions[["baseline"]]), 250)
  # nested per-session W3C-PROV provenance survives the round trip
  expect_identical(PhysioCore::provenanceHash(pl2@sessions[["baseline"]]), h_b)
  expect_identical(pl2@design$days_from_baseline, c(0, 42))
  expect_equal(pl2@subject$id, "sub-01")
})
