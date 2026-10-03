test_that("physioPut links an object's op-DAG into the lake lineage", {
  skip_if_not_installed("OmicsLake")
  skip_if_not_installed("PhysioPreprocess")

  set.seed(1)
  m <- matrix(rnorm(400 * 3), 400, 3); colnames(m) <- paste0("C", 1:3)
  pe <- PhysioExperiment(
    assays = S4Vectors::SimpleList(raw = m),
    colData = S4Vectors::DataFrame(name = colnames(m), type = "eeg"),
    samplingRate = 200)
  pe <- PhysioPreprocess::butterworthFilter(pe, low = 1, high = 40)

  lake <- new_test_lake()
  pn <- physioPut(lake, "eeg", pe)
  expect_equal(pn, "eeg__prov")

  # the op-DAG is a queryable companion table
  prov <- physioProvenance(lake, "eeg")
  expect_s3_class(prov, "data.frame")
  expect_true(nrow(prov) >= 1L)
  expect_true("butterworthFilter" %in% prov$activity)
  expect_true(".provenance_hash" %in% names(prov))

  # and a first-class lineage dependency of the object
  d <- lake$deps("eeg")
  expect_true("eeg__prov" %in% unlist(lapply(d, as.character)))

  # the object itself still round-trips as a PhysioExperiment
  pe2 <- lake$get("eeg")
  expect_s4_class(pe2, "PhysioExperiment")
  expect_identical(PhysioCore::provenanceHash(pe2), PhysioCore::provenanceHash(pe))
})

test_that("physioPut stores provenance-less objects without a companion table", {
  skip_if_not_installed("OmicsLake")
  pe <- PhysioExperiment(
    assays = S4Vectors::SimpleList(raw = matrix(rnorm(40), 10, 4)),
    colData = S4Vectors::DataFrame(name = paste0("C", 1:4), type = "eeg"),
    samplingRate = 100)   # no processing op -> no provenance
  lake <- new_test_lake()
  pn <- physioPut(lake, "raw", pe)
  expect_true(is.na(pn))
  expect_null(physioProvenance(lake, "raw"))
  expect_s4_class(lake$get("raw"), "PhysioExperiment")
})
