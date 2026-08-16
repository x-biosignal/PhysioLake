#' Store a Physio object in a lake with its provenance linked in the lineage
#'
#' Wraps [OmicsLake::Lake]'s `put()` so that the object's W3C-PROV operation DAG
#' (from [PhysioCore::provenance()]) is stored as a queryable companion table and
#' recorded as a **lineage dependency** of the object (via `put(..., depends_on
#' =)`). The ecosystem's per-object (micro) provenance thus becomes a first-class
#' node in OmicsLake's cross-dataset (macro) lineage, visible to `lake$tree()`,
#' `lake$deps()`, and `lake$impact()`.
#'
#' Objects that carry no provenance are stored normally (no companion table).
#'
#' @param lake An OmicsLake `Lake`.
#' @param name Object name.
#' @param x A Physio object, e.g. a [PhysioExperiment].
#' @param tags Character tags for the object (default `"physio"`).
#' @param provenance_suffix Suffix for the companion provenance table
#'   (default `"__prov"`).
#' @return Invisibly, the provenance table's name, or `NA_character_` if the
#'   object carried no provenance.
#' @seealso [physioProvenance()]
#' @export
physioPut <- function(lake, name, x, tags = "physio",
                      provenance_suffix = "__prov") {
  prov <- tryCatch(PhysioCore::provenance(x), error = function(e) NULL)
  if (!is.null(prov) && is.data.frame(prov) && nrow(prov) > 0) {
    prov_name <- paste0(name, provenance_suffix)
    prov[[".object"]] <- name
    prov[[".provenance_hash"]] <- tryCatch(PhysioCore::provenanceHash(x),
                                           error = function(e) NA_character_)
    lake$put(prov_name, prov, tags = "provenance")
    lake$put(name, x, depends_on = prov_name, tags = tags)
    invisible(prov_name)
  } else {
    lake$put(name, x, tags = tags)
    invisible(NA_character_)
  }
}

#' Retrieve the provenance op-DAG stored for a lake object
#'
#' Returns the companion provenance table written by [physioPut()].
#'
#' @param lake An OmicsLake `Lake`.
#' @param name Object name.
#' @param provenance_suffix Suffix used when storing (default `"__prov"`).
#' @return A data.frame of the operation DAG (one row per recorded activity), or
#'   `NULL` if none was stored.
#' @seealso [physioPut()]
#' @export
physioProvenance <- function(lake, name, provenance_suffix = "__prov") {
  pn <- paste0(name, provenance_suffix)
  tryCatch(lake$get(pn), error = function(e) NULL)
}
