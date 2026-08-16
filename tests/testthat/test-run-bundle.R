test_that("physioPutBundle stores a run bundle with internal lineage", {
  skip_if_not_installed("OmicsLake")

  # a substrate/agent run bundle: frozen prereg -> manifest -> {op-DAG, terminal}
  # -> claims (the AGENT-04/05 shape)
  components <- list(
    prereg   = list(hash = "abc123", registered_at = "2026-08-10T00:00:00Z"),
    manifest = list(seed = 100L, output_hash = "deb3c8f75d54db9c"),
    opdag    = data.frame(op = 1:2,
                          activity = c("ecgDetectRpeaks", "ecgHRVtime")),
    terminal = data.frame(channel = 1L, mean_hr = 72.03),
    claims   = data.frame(id = "mean_hr", status = "GROUNDED")
  )
  edges <- list(manifest = "prereg", opdag = "manifest",
                terminal = "manifest", claims = "terminal")

  lake <- new_test_lake()
  full <- physioPutBundle(lake, "run1", components, edges)

  expect_setequal(names(full), names(components))
  expect_equal(unname(full[["terminal"]]), "run1__terminal")

  # tables are queryable, objects deserialise
  expect_equal(as.data.frame(lake$get("run1__terminal"))$mean_hr, 72.03)
  expect_true("ecgHRVtime" %in% as.data.frame(lake$get("run1__opdag"))$activity)
  expect_equal(lake$get("run1__prereg")$hash, "abc123")

  # internal lineage edges recorded
  dep_of <- function(nm) unlist(lapply(lake$deps(nm), as.character))
  expect_true("run1__prereg"   %in% dep_of("run1__manifest"))
  expect_true("run1__manifest" %in% dep_of("run1__terminal"))
  expect_true("run1__terminal" %in% dep_of("run1__claims"))

  # the whole run can be snapshotted / versioned
  expect_no_error(lake$snap("run-v1"))
})
