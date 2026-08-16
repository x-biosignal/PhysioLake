test_that("PhysioExperiment round-trips through an OmicsLake with full fidelity", {
  skip_if_not_installed("OmicsLake")
  skip_if_not_installed("PhysioPreprocess")

  registerPhysioAdapters()

  set.seed(1)
  m <- matrix(rnorm(1000 * 4), 1000, 4); colnames(m) <- paste0("C", 1:4)
  pe <- PhysioExperiment(
    assays = S4Vectors::SimpleList(raw = m),
    colData = S4Vectors::DataFrame(name = colnames(m), type = "eeg"),
    samplingRate = 250)
  # a real provenance-recording op so metadata carries W3C-PROV provenance
  pe <- PhysioPreprocess::butterworthFilter(pe, low = 1, high = 40)
  h_before <- PhysioCore::provenanceHash(pe)
  n_before <- nrow(PhysioCore::provenance(pe))

  lake <- new_test_lake()
  lake$put("eeg", pe)
  pe2 <- lake$get("eeg")

  # class + sampling rate (what the generic SEAdapter would drop)
  expect_s4_class(pe2, "PhysioExperiment")
  expect_equal(PhysioCore::samplingRate(pe2), PhysioCore::samplingRate(pe))
  # assays preserved, filtered assay bit-identical
  expect_setequal(SummarizedExperiment::assayNames(pe2),
                  SummarizedExperiment::assayNames(pe))
  expect_equal(SummarizedExperiment::assay(pe2, "filtered"),
               SummarizedExperiment::assay(pe, "filtered"))
  # colData preserved
  expect_identical(as.character(SummarizedExperiment::colData(pe2)$name),
                   as.character(SummarizedExperiment::colData(pe)$name))
  # W3C-PROV provenance survives the round trip (micro -> lake)
  expect_equal(nrow(PhysioCore::provenance(pe2)), n_before)
  expect_identical(PhysioCore::provenanceHash(pe2), h_before)
})

test_that("the Physio adapter outranks the generic SummarizedExperiment adapter", {
  skip_if_not_installed("OmicsLake")
  registerPhysioAdapters()
  a <- PhysioExperimentAdapter$new()
  expect_gt(a$priority(), OmicsLake::SEAdapter$new()$priority())
  pe <- PhysioExperiment(
    assays = S4Vectors::SimpleList(raw = matrix(rnorm(40), 10, 4)),
    colData = S4Vectors::DataFrame(name = paste0("C", 1:4), type = "eeg"),
    samplingRate = 100)
  expect_true(a$can_handle(pe))
  expect_equal(OmicsLake:::find_adapter(pe)$name(), "PhysioExperiment")
})

test_that("events and free-form metadata survive the round trip", {
  skip_if_not_installed("OmicsLake")
  skip_if_not_installed("PhysioPreprocess")
  registerPhysioAdapters()

  set.seed(1)
  m <- matrix(rnorm(400 * 3), 400, 3); colnames(m) <- paste0("C", 1:3)
  pe <- PhysioPreprocess::butterworthFilter(
    PhysioExperiment(S4Vectors::SimpleList(raw = m),
                     colData = S4Vectors::DataFrame(name = colnames(m), type = "eeg"),
                     samplingRate = 250),
    low = 1, high = 40)
  # events (an event-table DataFrame) and an arbitrary scalar both live in metadata
  S4Vectors::metadata(pe)$events <- S4Vectors::DataFrame(
    onset = c(0.1, 0.5), label = c("stim", "resp"))
  S4Vectors::metadata(pe)$note <- "session A"

  lake <- new_test_lake()
  lake$put("eeg", pe)
  pe2 <- lake$get("eeg")

  expect_identical(as.data.frame(S4Vectors::metadata(pe2)$events),
                   as.data.frame(S4Vectors::metadata(pe)$events))
  expect_identical(S4Vectors::metadata(pe2)$note, "session A")
  # and provenance is still intact alongside the extra metadata
  expect_identical(PhysioCore::provenanceHash(pe2), PhysioCore::provenanceHash(pe))
})
