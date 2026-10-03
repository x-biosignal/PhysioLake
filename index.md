# PhysioLake

Versioned, lineage-tracked data management for the PhysioExperiment
ecosystem — a thin integration layer over
[OmicsLake](https://github.com/matsui-lab/OmicsLake).

## Installation

The ecosystem builds on Bioconductor, so its repositories have to be on
the list as well – without them the install stops at
`SummarizedExperiment`.

``` r

install.packages("BiocManager", repos = "https://cloud.r-project.org")
install.packages(
  "PhysioLake",
  repos = c("https://x-biosignal.r-universe.dev", BiocManager::repositories())
)
```

From GitHub instead:

``` r

install.packages("remotes", repos = "https://cloud.r-project.org")
remotes::install_github("x-biosignal/PhysioLake")
```

## Why not a new data lake?

OmicsLake already provides a mature, domain-agnostic core: a DuckDB /
Apache Arrow / Parquet backend, snapshots and time-travel, cross-dataset
lineage tracking, and a dplyr/query layer. Its *adapters*, however, are
written for omics object types (SummarizedExperiment,
SingleCellExperiment, MultiAssayExperiment, Spectra, XCMS, …) and do not
fit physiological-signal objects as-is.

PhysioLake therefore **inherits the OmicsLake core and adds only the
physiology delta**: ecosystem-specific adapters and utilities,
registered through OmicsLake’s public `register_adapter()` extension
point. No lake engine is reimplemented.

## What the Physio adapter preserves

A `PhysioExperiment` is a `SummarizedExperiment` subclass with an extra
`samplingRate` slot; its provenance, events, and derived estimates live
in `metadata()`. OmicsLake’s generic `SEAdapter` round-trips assays /
colData / rowData / metadata but reconstructs a *plain*
`SummarizedExperiment`, dropping the class identity and the sampling
rate. `PhysioExperimentAdapter` inherits it and restores exactly that —
so a round trip preserves the class, the sampling rate, every assay
bit-identically, and the **W3C-PROV provenance** (verified:
[`provenanceHash()`](https://x-biosignal.r-universe.dev/PhysioExperiment/reference/provenanceHash.html)
is identical before and after). The ecosystem’s per-object (micro)
provenance thus lands intact alongside the lake’s cross-dataset (macro)
lineage.

## Usage

``` r

library(PhysioLake)   # attaches PhysioExperiment; registers the adapters when OmicsLake is present

# Build a PhysioExperiment to store. Any ecosystem object works; this uses only
# hard dependencies, so it runs offline without OmicsLake.
pe <- PhysioExperiment(
  assays = list(raw = matrix(rnorm(400), nrow = 100, ncol = 4)),
  samplingRate = 250
)
provenanceHash(pe)    # the per-object W3C-PROV fingerprint the adapter preserves

# The lake round trip needs OmicsLake, an optional dependency (Suggests); it is
# not required to load PhysioLake or to build the objects the lake stores.
if (requireNamespace("OmicsLake", quietly = TRUE)) {
  lake <- OmicsLake::Lake$new("study")
  lake$put("eeg", pe)                        # stored with full fidelity
  pe2  <- lake$get("eeg")                     # a PhysioExperiment again
  stopifnot(identical(provenanceHash(pe2),    # provenance preserved by the round trip
                      provenanceHash(pe)))
  lake$snap("v1.0")                           # snapshot / time-travel
  lake$tree("eeg")                            # dataset lineage
}
```

## Coverage of the other physio types

`PhysioExperimentAdapter` exists only because a `PhysioExperiment` *is*
a `SummarizedExperiment`, so OmicsLake’s generic `SEAdapter` would
otherwise intercept it and drop the class and sampling rate. The other
physio types (`MultiRatePhysioExperiment`, `PhysioLongitudinal`,
`AnalysisResult`) are **not** `SummarizedExperiment` subclasses, so
nothing intercepts them and OmicsLake’s default object storage
serialises them with full fidelity — verified to preserve the class, all
slots, and **nested `PhysioExperiment` provenance** (a MultiRate’s inner
PE keeps its
[`provenanceHash()`](https://x-biosignal.r-universe.dev/PhysioExperiment/reference/provenanceHash.html)).
No bespoke storage adapters are needed for these; PhysioLake pins that
guarantee with tests.

## Provenance bridge: micro op-DAG → macro lineage

[`physioPut()`](https://x-biosignal.github.io/PhysioLake/reference/physioPut.md)
stores an object *and* its W3C-PROV operation DAG (from
[`PhysioCore::provenance()`](https://x-biosignal.r-universe.dev/PhysioExperiment/reference/provenance.html))
as a queryable companion table, recorded as a **lineage dependency** of
the object via OmicsLake’s `depends_on`. The per-object provenance thus
becomes a first-class node in the cross-dataset lineage:

``` r

if (requireNamespace("OmicsLake", quietly = TRUE)) {
  lake <- OmicsLake::Lake$new("study")
  physioPut(lake, "eeg", pe)     # stores pe AND its op-DAG as a lineage dependency
  lake$tree("eeg")
  #>   child    parent parent_type relationship depth
  #> 1   eeg eeg__prov       table derived_from     0
  physioProvenance(lake, "eeg")  # the op-DAG as a queryable table (activity, ...)
}
```

## Run bundles: versioned, lineage-tracked substrate/agent runs

[`physioPutBundle()`](https://x-biosignal.github.io/PhysioLake/reference/physioPutBundle.md)
stores the parts of a reproducibility-substrate / PhysioAgent run bundle
(frozen pre-registration, run manifest, op-DAG, terminal artifact,
claims, …) as individual lake entries wired together with lineage edges,
so the run’s internal structure is queryable and a `lake$snap()`
versions the whole run:

``` r

if (requireNamespace("OmicsLake", quietly = TRUE)) {
  lake <- OmicsLake::Lake$new("study")
  frozen       <- data.frame(key = "design", value = "pre-registered")
  run_manifest <- data.frame(step = "analyse", tool = "PhysioAgent")
  op_dag_df    <- data.frame(activity = "butterworthFilter", used = "raw")
  terminal_df  <- data.frame(metric = "sdnn", value = 1.389)
  claims_df    <- data.frame(claim = "within-reference", supported = TRUE)
  physioPutBundle(lake, "run1", components = list(
    prereg = frozen, manifest = run_manifest, opdag = op_dag_df,
    terminal = terminal_df, claims = claims_df),
    edges = list(manifest = "prereg", opdag = "manifest",
                 terminal = "manifest", claims = "terminal"))
  lake$tree("run1__claims")   # claims <- terminal <- manifest <- prereg
}
```

This gives the reproducibility substrate the persistent, queryable store
it otherwise lacks (it content-addresses runs but does not persist
them).

## Status

Early-stage (0.1.0); `R CMD check` clean. Covers PhysioExperiment
(adapter, including 3-D epoched *time x channel x trial* assays), the
other physio types (`MultiRatePhysioExperiment`, `PhysioLongitudinal`,
`AnalysisResult`; default serialization), the provenance bridge, and run
bundles. A public x-biosignal / r-universe release needs OmicsLake
resolvable in that build — it is published at
[`x-biosignal.r-universe.dev`](https://x-biosignal.r-universe.dev), so
add `Additional_repositories: https://x-biosignal.r-universe.dev` (or
rely on the `Remotes` field).

Snapshot / time-travel works end-to-end: `lake$snap("v1")` versions a
`PhysioExperiment` and `lake$restore("v1")` rolls it back — including
the sampling rate and W3C-PROV provenance held in the SE object
metadata, not just the assay / colData / rowData tables. This needs the
object-restore fix in **OmicsLake (\>= 0.99.4)**; the round trip is
verified in `tests/testthat/test-snapshot.R`.
