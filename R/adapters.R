#' PhysioExperiment adapter for OmicsLake
#'
#' An [OmicsLake::LakeAdapter] that stores and retrieves [PhysioExperiment]
#' objects in an OmicsLake with full fidelity.
#'
#' A `PhysioExperiment` is a `SummarizedExperiment` subclass with one extra slot
#' (`samplingRate`); its provenance, events, and derived estimates live in
#' `metadata()`. OmicsLake's generic `SEAdapter` already round-trips assays,
#' `colData`, `rowData`, and `metadata`, but it reconstructs a *plain*
#' `SummarizedExperiment` -- losing the class identity and the sampling rate.
#' This adapter inherits `SEAdapter` and adds only that missing piece: it stashes
#' the sampling rate in metadata on `put()` and rebuilds a `PhysioExperiment` on
#' `get()`. Because provenance is carried in `metadata()`, it survives the round
#' trip unchanged (verified: `provenanceHash()` is identical before and after),
#' so the ecosystem's per-object (micro) W3C-PROV provenance lands intact next to
#' OmicsLake's cross-dataset (macro) lineage. Assays that are not 2-D matrices
#' (e.g. epoched *time x channel x trial* arrays), which the generic `SEAdapter`
#' would collapse when storing them as flat tables, are likewise stashed in
#' metadata and spliced back in their original order on `get()`.
#'
#' A higher `priority()` than the generic `SEAdapter` ensures this adapter is
#' selected for `PhysioExperiment` objects (which also satisfy `SEAdapter`).
#'
#' @return An R6 generator for the `PhysioExperimentAdapter`.
#' @seealso [registerPhysioAdapters()], [OmicsLake::register_adapter()]
#' @export
PhysioExperimentAdapter <- R6::R6Class(
  "PhysioExperimentAdapter",
  inherit = OmicsLake::SEAdapter,
  public = list(
    #' @description Adapter type name.
    name = function() "PhysioExperiment",
    #' @description Whether this adapter handles `data`.
    #' @param data An object to test.
    can_handle = function(data) inherits(data, "PhysioExperiment"),
    #' @description Selection priority (above the generic SummarizedExperiment
    #'   adapter, which is 100).
    priority = function() 200L,
    #' @description Store a `PhysioExperiment` in the lake.
    #' @param lake An OmicsLake `Lake`.
    #' @param name Object name.
    #' @param data A `PhysioExperiment`.
    put = function(lake, name, data) {
      md <- S4Vectors::metadata(data)
      md[[".physio_sampling_rate"]] <- as.numeric(PhysioCore::samplingRate(data))
      # Row dimnames (usually NULL for time-series) list-wrapped so a genuine NULL
      # survives; the generic SE reconstruction otherwise synthesises "row1"...
      md[[".physio_rownames"]] <- list(rownames(data))
      # Non-2D assays (e.g. epoched time x channel x trial arrays) cannot be
      # stored as flat tables by the generic SEAdapter, which silently collapses
      # them. Stash any such assay in metadata -- which round-trips as a
      # serialized object with full fidelity -- and restore it on get().
      a <- as.list(SummarizedExperiment::assays(data, withDimnames = FALSE))
      is_nd <- vapply(a, function(x) length(dim(x)) != 2L, logical(1))
      if (any(is_nd)) {
        md[[".physio_nd_assays"]]  <- a[is_nd]
        md[[".physio_assay_order"]] <- names(a)
        flat <- a[!is_nd]
        if (length(flat) == 0L) {
          # No 2D assay left to carry the dims: keep a tiny placeholder so the
          # stored SummarizedExperiment stays valid; dropped again on get().
          md[[".physio_nd_placeholder"]] <- TRUE
          flat <- list(.physio_placeholder = matrix(0, nrow(data), ncol(data)))
        }
        SummarizedExperiment::assays(data, withDimnames = FALSE) <-
          methods::as(flat, "SimpleList")
      }
      S4Vectors::metadata(data) <- md
      super$put(lake, name, data)
    },
    #' @description Retrieve a `PhysioExperiment` from the lake.
    #' @param lake An OmicsLake `Lake`.
    #' @param name Object name.
    #' @param ref Version reference (default `"@latest"`).
    get = function(lake, name, ref = "@latest") {
      se <- super$get(lake, name, ref)
      md <- S4Vectors::metadata(se)
      sr  <- md[[".physio_sampling_rate"]];  md[[".physio_sampling_rate"]]  <- NULL
      rn  <- md[[".physio_rownames"]];       md[[".physio_rownames"]]       <- NULL
      nd  <- md[[".physio_nd_assays"]];      md[[".physio_nd_assays"]]      <- NULL
      ord <- md[[".physio_assay_order"]];    md[[".physio_assay_order"]]    <- NULL
      ph  <- isTRUE(md[[".physio_nd_placeholder"]]); md[[".physio_nd_placeholder"]] <- NULL
      if (!is.null(nd)) {
        # Splice the stashed non-2D assays back in, restoring the original order.
        a <- as.list(SummarizedExperiment::assays(se, withDimnames = FALSE))
        if (ph) a[[".physio_placeholder"]] <- NULL
        a <- c(a, nd)
        if (!is.null(ord)) a <- a[ord]
        SummarizedExperiment::assays(se, withDimnames = FALSE) <-
          methods::as(a, "SimpleList")
      }
      S4Vectors::metadata(se) <- md
      if (!is.null(rn)) rownames(se) <- rn[[1]]   # restore original row dimnames (incl. NULL)
      methods::new("PhysioExperiment", se, samplingRate = as.numeric(sr))
    }
  )
)

#' Register the Physio adapters with OmicsLake
#'
#' Registers PhysioLake's adapters (currently [PhysioExperimentAdapter]) with the
#' OmicsLake adapter registry so that `lake$put()` / `lake$get()` handle Physio
#' objects automatically. Called on package load; exported so it can be re-run
#' after `OmicsLake::clear_adapters()`.
#'
#' @return Invisibly `TRUE`.
#' @export
registerPhysioAdapters <- function() {
  OmicsLake::register_adapter(PhysioExperimentAdapter$new())
  invisible(TRUE)
}
