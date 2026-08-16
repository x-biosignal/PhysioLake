# Epoched physiological data is naturally 3-D (time x channel x trial). OmicsLake's
# generic SEAdapter stores assays as flat tables and silently collapses arrays with
# more than two dimensions, so PhysioExperimentAdapter stashes any non-2-D assay in
# metadata (which round-trips as a serialized object) and splices it back on get().
# These tests pin that fidelity. Assay values are compared with withDimnames = FALSE
# because SummarizedExperiment synthesises dimnames on access; channel identity is
# carried separately by colData (checked elsewhere).

test_that("3D (epoched) PhysioExperiment assays round-trip bit-identically", {
  skip_if_not_installed("OmicsLake")
  registerPhysioAdapters()

  set.seed(2)
  arr <- array(rnorm(100 * 4 * 3), dim = c(100, 4, 3))
  pe <- PhysioExperiment(
    assays = S4Vectors::SimpleList(epoch = arr),
    rowData = S4Vectors::DataFrame(t = seq_len(100)),
    colData = S4Vectors::DataFrame(name = paste0("C", 1:4), type = "eeg"),
    samplingRate = 256)

  lake <- new_test_lake()
  lake$put("ep", pe)
  pe2 <- lake$get("ep")

  expect_s4_class(pe2, "PhysioExperiment")
  expect_identical(dim(SummarizedExperiment::assay(pe2, "epoch")), c(100L, 4L, 3L))
  expect_identical(
    SummarizedExperiment::assay(pe2, "epoch", withDimnames = FALSE), arr)
  expect_equal(PhysioCore::samplingRate(pe2), 256)
  expect_identical(SummarizedExperiment::rowData(pe2)$t, seq_len(100))
  # internal stash keys must not leak into user-visible metadata
  expect_false(any(grepl("^\\.physio_", names(S4Vectors::metadata(pe2)))))
})

test_that("mixed 2D + 3D assays keep their original order and fidelity", {
  skip_if_not_installed("OmicsLake")
  registerPhysioAdapters()

  set.seed(3)
  raw   <- matrix(rnorm(100 * 4), 100, 4)
  epoch <- array(rnorm(100 * 4 * 5), dim = c(100, 4, 5))
  pe <- PhysioExperiment(
    assays = S4Vectors::SimpleList(raw = raw, epoch = epoch),
    colData = S4Vectors::DataFrame(name = paste0("C", 1:4)),
    samplingRate = 200)

  lake <- new_test_lake()
  lake$put("m", pe)
  pe2 <- lake$get("m")

  expect_identical(SummarizedExperiment::assayNames(pe2), c("raw", "epoch"))
  # 2D assays go through the generic SEAdapter, which synthesises column dimnames;
  # compare values (channel identity is carried by colData, not assay dimnames).
  expect_equal(
    unname(SummarizedExperiment::assay(pe2, "raw", withDimnames = FALSE)),
    unname(raw))
  # the 3D assay is stashed verbatim in metadata, so it stays bit-identical
  expect_identical(
    SummarizedExperiment::assay(pe2, "epoch", withDimnames = FALSE), epoch)
  # the internal dims-preserving placeholder must never surface
  expect_false(".physio_placeholder" %in% SummarizedExperiment::assayNames(pe2))
})
