# Store a Physio object in a lake with its provenance linked in the lineage

Wraps [OmicsLake::Lake](https://rdrr.io/pkg/OmicsLake/man/Lake.html)'s
`put()` so that the object's W3C-PROV operation DAG (from
[`PhysioExperiment::provenance()`](https://x-biosignal.r-universe.dev/PhysioExperiment/reference/provenance.html))
is stored as a queryable companion table and recorded as a **lineage
dependency** of the object (via `put(..., depends_on =)`). The
ecosystem's per-object (micro) provenance thus becomes a first-class
node in OmicsLake's cross-dataset (macro) lineage, visible to
`lake$tree()`, `lake$deps()`, and `lake$impact()`.

## Usage

``` r
physioPut(lake, name, x, tags = "physio", provenance_suffix = "__prov")
```

## Arguments

- lake:

  An OmicsLake `Lake`.

- name:

  Object name.

- x:

  A Physio object, e.g. a
  [PhysioExperiment](https://x-biosignal.r-universe.dev/PhysioExperiment/reference/PhysioExperiment.html).

- tags:

  Character tags for the object (default `"physio"`).

- provenance_suffix:

  Suffix for the companion provenance table (default `"__prov"`).

## Value

Invisibly, the provenance table's name, or `NA_character_` if the object
carried no provenance.

## Details

Objects that carry no provenance are stored normally (no companion
table).

## See also

[`physioProvenance()`](https://x-biosignal.github.io/PhysioLake/reference/physioProvenance.md)

## Examples

``` r
if (requireNamespace("OmicsLake", quietly = TRUE)) {
  lake <- OmicsLake::Lake$new(basename(tempfile("lake")), root = tempdir())
  pe <- PhysioExperiment::PhysioExperiment(
    assays = list(raw = matrix(as.numeric(1:20), nrow = 10, ncol = 2)),
    samplingRate = 100
  )
  physioPut(lake, "subj01", pe)
  restored <- lake$get("subj01")        # a PhysioExperiment again
  PhysioExperiment::samplingRate(restored)
}
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpBjG6Iw/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> [1] 100
```
