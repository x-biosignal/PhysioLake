# Store a reproducibility-substrate / PhysioAgent run bundle in a lake

Stores the parts of a run bundle (e.g. the frozen pre-registration, the
run manifest, the operation DAG, the terminal artifact, the claims
registry, the verification report) as individual OmicsLake entries under
a common prefix, wired together with lineage edges so the run's internal
structure is queryable via `lake$tree()` / `lake$deps()`. Combined with
`lake$snap()`, a whole run becomes a versioned, lineage-tracked lake
object — giving the substrate the persistent, queryable store it
otherwise lacks (it content-addresses runs but does not persist them).

## Usage

``` r
physioPutBundle(lake, name, components, edges = list(), tags = "run-bundle")
```

## Arguments

- lake:

  An OmicsLake `Lake`.

- name:

  Bundle name; used as the entry prefix (`"<name>__<key>"`).

- components:

  Named list of bundle parts.

- edges:

  Named list: for each component key, a character vector of the
  component keys it depends on (a within-bundle lineage DAG).

- tags:

  Character tags applied to every entry (default `"run-bundle"`).

## Value

Invisibly, a named character vector mapping each component key to its
stored lake entry name.

## Details

`data.frame` components are stored as queryable tables; other objects
are serialised. Components are stored parents-first (topological order
over `edges`) so each `depends_on` target already exists.

## See also

[`physioPut()`](https://x-biosignal.github.io/PhysioLake/reference/physioPut.md)

## Examples

``` r
if (requireNamespace("OmicsLake", quietly = TRUE)) {
  lake <- OmicsLake::Lake$new(basename(tempfile("lake")), root = tempdir())
  components <- list(
    prereg = data.frame(key = "alpha", value = 1),
    result = data.frame(metric = "hr", value = 72)
  )
  # `result` depends on `prereg`; the bundle stores that lineage edge.
  physioPutBundle(lake, "run001", components,
                  edges = list(result = "prereg"))
  lake$deps("run001__result")
}
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpBjG6Iw/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#>      parent_name parent_type relationship_type          created_at parent_ref
#> 1 run001__prereg       table      derived_from 2026-10-03 13:28:49    @latest
#>        parent_version_id
#> 1 run001__prereg@current
```
