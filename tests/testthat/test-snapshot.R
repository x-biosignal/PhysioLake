# Snapshot / time-travel for PhysioExperiment. lake$snap() versions the object and
# lake$restore() rolls the lake back to a snapshot. A PhysioExperiment is stored via
# the SEAdapter as a mix of table components (assay / colData / rowData) and object
# components (the SE manifest + metadata, where PhysioLake stashes the sampling rate
# and where W3C-PROV provenance lives). Both kinds must roll back together. This
# needs the object-restore fix in OmicsLake (>= 0.99.4); earlier versions restored
# only the table components, leaving samplingRate / provenance at the newer version.
# Assay values are compared unnamed because the flat-table store synthesises assay
# dimnames (channel identity is carried by colData).

test_that("snapshot + restore rolls a PhysioExperiment back to a prior version", {
  skip_if_not_installed("OmicsLake")
  skip_if_not_installed("PhysioPreprocess")

  registerPhysioAdapters()
  mk <- function(sr, seed) {
    set.seed(seed)
    m <- matrix(rnorm(400 * 3), 400, 3); colnames(m) <- paste0("C", 1:3)
    PhysioPreprocess::butterworthFilter(
      PhysioExperiment(S4Vectors::SimpleList(raw = m),
                       colData = S4Vectors::DataFrame(name = colnames(m), type = "eeg"),
                       samplingRate = sr),
      low = 1, high = 40)
  }

  v1 <- mk(250, 1)
  h1 <- PhysioCore::provenanceHash(v1)
  a1 <- SummarizedExperiment::assay(v1, "filtered", withDimnames = FALSE)

  lake <- new_test_lake()
  lake$put("eeg", v1)
  lake$snap("v1")
  lake$put("eeg", mk(999, 7))                       # a newer version

  expect_equal(PhysioCore::samplingRate(lake$get("eeg")), 999)   # latest

  lake$restore("v1")
  past <- lake$get("eeg")
  expect_s4_class(past, "PhysioExperiment")
  expect_equal(PhysioCore::samplingRate(past), 250)              # object metadata rolled back
  expect_identical(PhysioCore::provenanceHash(past), h1)         # provenance rolled back
  expect_equal(                                                  # assay data rolled back
    unname(SummarizedExperiment::assay(past, "filtered", withDimnames = FALSE)),
    unname(a1))
})
