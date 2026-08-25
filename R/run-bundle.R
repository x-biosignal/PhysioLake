#' Store a reproducibility-substrate / PhysioAgent run bundle in a lake
#'
#' Stores the parts of a run bundle (e.g. the frozen pre-registration, the run
#' manifest, the operation DAG, the terminal artifact, the claims registry, the
#' verification report) as individual OmicsLake entries under a common prefix,
#' wired together with lineage edges so the run's internal structure is queryable
#' via `lake$tree()` / `lake$deps()`. Combined with `lake$snap()`, a whole run
#' becomes a versioned, lineage-tracked lake object — giving the substrate the
#' persistent, queryable store it otherwise lacks (it content-addresses runs but
#' does not persist them).
#'
#' `data.frame` components are stored as queryable tables; other objects are
#' serialised. Components are stored parents-first (topological order over
#' `edges`) so each `depends_on` target already exists.
#'
#' @param lake An OmicsLake `Lake`.
#' @param name Bundle name; used as the entry prefix (`"<name>__<key>"`).
#' @param components Named list of bundle parts.
#' @param edges Named list: for each component key, a character vector of the
#'   component keys it depends on (a within-bundle lineage DAG).
#' @param tags Character tags applied to every entry (default `"run-bundle"`).
#' @return Invisibly, a named character vector mapping each component key to its
#'   stored lake entry name.
#' @seealso [physioPut()]
#' @export
physioPutBundle <- function(lake, name, components, edges = list(),
                            tags = "run-bundle") {
  stopifnot(is.list(components), length(components) > 0L,
            !is.null(names(components)), all(nzchar(names(components))))
  keys <- names(components)
  full <- stats::setNames(paste0(name, "__", keys), keys)
  done <- character(0)
  pending <- keys
  repeat {
    ready <- pending[vapply(pending, function(k) {
      d <- edges[[k]]; is.null(d) || all(d %in% done)
    }, logical(1))]
    if (!length(ready)) break
    for (k in ready) {
      d <- edges[[k]]
      lake$put(full[[k]], components[[k]],
               depends_on = if (is.null(d)) NULL else unname(full[d]),
               tags = tags)
      done <- c(done, k)
    }
    pending <- setdiff(pending, ready)
  }
  # any leftover (cyclic / unresolved deps) stored without lineage edges
  for (k in pending) lake$put(full[[k]], components[[k]], tags = tags)
  invisible(full)
}
