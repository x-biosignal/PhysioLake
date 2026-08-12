# PhysioExperiment adapter for OmicsLake

PhysioExperiment adapter for OmicsLake

PhysioExperiment adapter for OmicsLake

## Value

An R6 generator for the `PhysioExperimentAdapter`.

## Details

An
[OmicsLake::LakeAdapter](https://rdrr.io/pkg/OmicsLake/man/LakeAdapter.html)
that stores and retrieves
[PhysioCore::PhysioExperiment](https://x-biosignal.r-universe.dev/PhysioCore/reference/PhysioExperiment.html)
objects in an OmicsLake with full fidelity.

A `PhysioExperiment` is a `SummarizedExperiment` subclass with one extra
slot (`samplingRate`); its provenance, events, and derived estimates
live in `metadata()`. OmicsLake's generic `SEAdapter` already
round-trips assays, `colData`, `rowData`, and `metadata`, but it
reconstructs a *plain* `SummarizedExperiment` – losing the class
identity and the sampling rate. This adapter inherits `SEAdapter` and
adds only that missing piece: it stashes the sampling rate in metadata
on `put()` and rebuilds a `PhysioExperiment` on
[`get()`](https://rdrr.io/r/base/get.html). Because provenance is
carried in `metadata()`, it survives the round trip unchanged (verified:
[`provenanceHash()`](https://x-biosignal.r-universe.dev/PhysioCore/reference/provenanceHash.html)
is identical before and after), so the ecosystem's per-object (micro)
W3C-PROV provenance lands intact next to OmicsLake's cross-dataset
(macro) lineage. Assays that are not 2-D matrices (e.g. epoched *time x
channel x trial* arrays), which the generic `SEAdapter` would collapse
when storing them as flat tables, are likewise stashed in metadata and
spliced back in their original order on
[`get()`](https://rdrr.io/r/base/get.html).

A higher `priority()` than the generic `SEAdapter` ensures this adapter
is selected for `PhysioExperiment` objects (which also satisfy
`SEAdapter`).

## See also

[`registerPhysioAdapters()`](https://x-biosignal.github.io/PhysioLake/reference/registerPhysioAdapters.md),
[`OmicsLake::register_adapter()`](https://rdrr.io/pkg/OmicsLake/man/register_adapter.html)

## Super classes

[`OmicsLake::LakeAdapter`](https://rdrr.io/pkg/OmicsLake/man/LakeAdapter.html)
-\>
[`OmicsLake::SEAdapter`](https://rdrr.io/pkg/OmicsLake/man/SEAdapter.html)
-\> `PhysioExperimentAdapter`

## Methods

### Public methods

- [`PhysioExperimentAdapter$name()`](#method-PhysioExperimentAdapter-name)

- [`PhysioExperimentAdapter$can_handle()`](#method-PhysioExperimentAdapter-can_handle)

- [`PhysioExperimentAdapter$priority()`](#method-PhysioExperimentAdapter-priority)

- [`PhysioExperimentAdapter$put()`](#method-PhysioExperimentAdapter-put)

- [`PhysioExperimentAdapter$get()`](#method-PhysioExperimentAdapter-get)

- [`PhysioExperimentAdapter$clone()`](#method-PhysioExperimentAdapter-clone)

Inherited methods

- [`OmicsLake::SEAdapter$components()`](https://rdrr.io/pkg/OmicsLake/man/SEAdapter.html#method-components)
- [`OmicsLake::SEAdapter$exists()`](https://rdrr.io/pkg/OmicsLake/man/SEAdapter.html#method-exists)
- [`OmicsLake::SEAdapter$list_names()`](https://rdrr.io/pkg/OmicsLake/man/SEAdapter.html#method-list_names)

------------------------------------------------------------------------

### Method `name()`

Adapter type name.

#### Usage

    PhysioExperimentAdapter$name()

------------------------------------------------------------------------

### Method `can_handle()`

Whether this adapter handles `data`.

#### Usage

    PhysioExperimentAdapter$can_handle(data)

#### Arguments

- `data`:

  An object to test.

------------------------------------------------------------------------

### Method `priority()`

Selection priority (above the generic SummarizedExperiment adapter,
which is 100).

#### Usage

    PhysioExperimentAdapter$priority()

------------------------------------------------------------------------

### Method `put()`

Store a `PhysioExperiment` in the lake.

#### Usage

    PhysioExperimentAdapter$put(lake, name, data)

#### Arguments

- `lake`:

  An OmicsLake `Lake`.

- `name`:

  Object name.

- `data`:

  A `PhysioExperiment`.

------------------------------------------------------------------------

### Method [`get()`](https://rdrr.io/r/base/get.html)

Retrieve a `PhysioExperiment` from the lake.

#### Usage

    PhysioExperimentAdapter$get(lake, name, ref = "@latest")

#### Arguments

- `lake`:

  An OmicsLake `Lake`.

- `name`:

  Object name.

- `ref`:

  Version reference (default `"@latest"`).

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    PhysioExperimentAdapter$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
