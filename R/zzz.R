.onLoad <- function(libname, pkgname) {
  # Register the Physio adapters with OmicsLake, but only if OmicsLake is
  # available and initialised -- never force-load Python/DuckDB machinery here.
  if (requireNamespace("OmicsLake", quietly = TRUE)) {
    try(registerPhysioAdapters(), silent = TRUE)
  }
}
