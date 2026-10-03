# Retrieve the provenance op-DAG stored for a lake object

Returns the companion provenance table written by
[`physioPut()`](https://x-biosignal.github.io/PhysioLake/reference/physioPut.md).

## Usage

``` r
physioProvenance(lake, name, provenance_suffix = "__prov")
```

## Arguments

- lake:

  An OmicsLake `Lake`.

- name:

  Object name.

- provenance_suffix:

  Suffix used when storing (default `"__prov"`).

## Value

A data.frame of the operation DAG (one row per recorded activity), or
`NULL` if none was stored.

## See also

[`physioPut()`](https://x-biosignal.github.io/PhysioLake/reference/physioPut.md)

## Examples

``` r
if (requireNamespace("OmicsLake", quietly = TRUE)) {
  lake <- OmicsLake::Lake$new(basename(tempfile("lake")), root = tempdir())
  pe <- PhysioExperiment::PhysioExperiment(
    assays = list(raw = matrix(as.numeric(1:20), nrow = 10, ncol = 2)),
    samplingRate = 100
  )
  physioPut(lake, "subj01", pe)
  # NULL here because this object carries no recorded op-DAG.
  physioProvenance(lake, "subj01")
}
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpBjG6Iw/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> NULL
```
