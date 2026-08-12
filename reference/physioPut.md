# Store a Physio object in a lake with its provenance linked in the lineage

Wraps [OmicsLake::Lake](https://rdrr.io/pkg/OmicsLake/man/Lake.html)'s
`put()` so that the object's W3C-PROV operation DAG (from
[`PhysioCore::provenance()`](https://x-biosignal.r-universe.dev/PhysioCore/reference/provenance.html))
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
  [PhysioCore::PhysioExperiment](https://x-biosignal.r-universe.dev/PhysioCore/reference/PhysioExperiment.html).

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
