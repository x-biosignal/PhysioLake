# Changelog

## PhysioLake 0.1.1

- Tests now build their OmicsLake from a project name under a temporary
  root instead of passing a
  [`tempfile()`](https://rdrr.io/r/base/tempfile.html) path as the
  project identifier. The old form worked on Unix by accident but broke
  the DuckDB backend on Windows, where the drive-letter colon makes the
  resolved lake path invalid. No runtime change.

## PhysioLake 0.1.0

- Initial draft. Integrates the ecosystem with OmicsLake by inheriting
  its domain-agnostic core (DuckDB/Arrow/Parquet backend,
  snapshots/time-travel, cross-dataset lineage, query layer) and
  registering a physiology-specific adapter through OmicsLake’s
  `register_adapter()` extension point.
- `PhysioExperimentAdapter` (inherits
  [`OmicsLake::SEAdapter`](https://rdrr.io/pkg/OmicsLake/man/SEAdapter.html))
  stores and retrieves `PhysioExperiment` objects with full fidelity: it
  preserves the class identity and the `samplingRate` slot that the
  generic SummarizedExperiment adapter would drop, and — because
  provenance rides in `metadata()` — the W3C-PROV provenance survives
  the round trip unchanged
  ([`provenanceHash()`](https://x-biosignal.github.io/PhysioCore//reference/provenanceHash.html)
  identical before and after). Registered on load via `.onLoad`;
  re-runnable with
  [`registerPhysioAdapters()`](https://x-biosignal.github.io/PhysioLake/reference/registerPhysioAdapters.md).
- Verified that the non-SummarizedExperiment physio types
  (`MultiRatePhysioExperiment`, `PhysioLongitudinal`, `AnalysisResult`)
  round-trip through the lake with full fidelity via OmicsLake’s default
  object serialization — including nested `PhysioExperiment` provenance
  — so no bespoke storage adapters are needed for them (pinned by
  `test-containers.R`).
- [`physioPut()`](https://x-biosignal.github.io/PhysioLake/reference/physioPut.md)
  /
  [`physioProvenance()`](https://x-biosignal.github.io/PhysioLake/reference/physioProvenance.md):
  a provenance bridge that stores an object’s W3C-PROV op-DAG (from
  [`PhysioCore::provenance()`](https://x-biosignal.github.io/PhysioCore//reference/provenance.html))
  as a queryable companion table and records it as a lineage dependency
  (`put(..., depends_on=)`), so the per-object (micro) provenance
  becomes a first-class node in OmicsLake’s cross-dataset (macro)
  lineage – `lake$tree()` / `deps()` / `impact()` see it.
- [`physioPutBundle()`](https://x-biosignal.github.io/PhysioLake/reference/physioPutBundle.md):
  store a reproducibility-substrate / PhysioAgent run bundle (frozen
  prereg, run manifest, op-DAG, terminal artifact, claims, …) as
  individual lake entries wired with internal lineage edges (stored
  parents-first by topological order), so a whole run becomes a
  versioned, lineage-tracked lake object queryable via `tree()` /
  `deps()`. Gives the substrate the persistent store it lacks (it
  content-addresses runs but does not persist them).
