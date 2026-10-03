# Versioned, lineage-tracked storage for PhysioExperiment objects

PhysioLake connects the PhysioExperiment ecosystem to
[OmicsLake](https://github.com/matsui-lab/OmicsLake) – a versioned,
on-disk data-management engine (DuckDB + Apache Arrow + Parquet) with
automatic cross-dataset lineage. PhysioLake does **not** reimplement a
data lake; it adds a thin layer so that:

- a `PhysioExperiment` round-trips with **full fidelity** – its class
  identity, `samplingRate` slot, non-2-D (epoched) assays, and W3C-PROV
  metadata all survive, and
- each object’s **per-object (micro) provenance** becomes a first-class
  node in OmicsLake’s **cross-dataset (macro) lineage**.

OmicsLake is an optional backend (a `Suggests` dependency), so
PhysioLake stays standalone-installable. The code below runs only when
it is available:

``` r

has_ol
#> [1] TRUE
```

## A tiny local lake

A `Lake`’s first constructor argument is a project *name*, not a path;
the lake lives under `root`. Here we create a throwaway lake in the
session temp dir.

``` r

library(PhysioLake)
#> Loading required package: PhysioExperiment
lake <- OmicsLake::Lake$new(basename(tempfile("lake")), root = tempdir())
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/Rtmp4KKhbH/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
```

## Store and retrieve a PhysioExperiment

[`physioPut()`](https://x-biosignal.github.io/PhysioLake/reference/physioPut.md)
stores the object (and, if present, its operation DAG as a queryable
companion table wired in as a lineage dependency). `lake$get()` returns
a genuine `PhysioExperiment`, not a bare `SummarizedExperiment`.

``` r

pe <- PhysioExperiment::PhysioExperiment(
  assays = list(raw = matrix(as.numeric(1:20), nrow = 10, ncol = 2)),
  samplingRate = 100
)
physioPut(lake, "subj01", pe)

restored <- lake$get("subj01")
class(restored)
#> [1] "PhysioExperiment"
#> attr(,"package")
#> [1] "PhysioExperiment"
PhysioExperiment::samplingRate(restored)
#> [1] 100
```

The sampling rate and class identity survive the round trip – the piece
the generic SummarizedExperiment adapter would otherwise drop.

## Store a run bundle with internal lineage

[`physioPutBundle()`](https://x-biosignal.github.io/PhysioLake/reference/physioPutBundle.md)
stores the parts of a reproducible run (pre-registration, results,
reports, …) as individual lake entries wired together with lineage
edges, so the run’s internal structure is queryable.

``` r

components <- list(
  prereg = data.frame(key = "alpha", value = 1),
  result = data.frame(metric = "hr", value = 72)
)
physioPutBundle(lake, "run001", components,
                edges = list(result = "prereg"))

# `result` records `prereg` as an upstream dependency:
lake$deps("run001__result")
#>      parent_name parent_type relationship_type          created_at parent_ref
#> 1 run001__prereg       table      derived_from 2026-10-03 13:28:56    @latest
#>        parent_version_id
#> 1 run001__prereg@current
```

## Where to go next

- [`?physioPut`](https://x-biosignal.github.io/PhysioLake/reference/physioPut.md)
  /
  [`?physioProvenance`](https://x-biosignal.github.io/PhysioLake/reference/physioProvenance.md)
  – object storage and provenance retrieval.
- [`?physioPutBundle`](https://x-biosignal.github.io/PhysioLake/reference/physioPutBundle.md)
  – storing a whole reproducible run.
- [`?PhysioExperimentAdapter`](https://x-biosignal.github.io/PhysioLake/reference/PhysioExperimentAdapter.md)
  – the fidelity-preserving storage adapter.
- OmicsLake’s own documentation for snapshots, time-travel, and lineage
  queries (`lake$snap()`, `lake$tree()`, `lake$impact()`).
