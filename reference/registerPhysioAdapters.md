# Register the Physio adapters with OmicsLake

Registers PhysioLake's adapters (currently
[PhysioExperimentAdapter](https://x-biosignal.github.io/PhysioLake/reference/PhysioExperimentAdapter.md))
with the OmicsLake adapter registry so that `lake$put()` / `lake$get()`
handle Physio objects automatically. Called on package load; exported so
it can be re-run after
[`OmicsLake::clear_adapters()`](https://rdrr.io/pkg/OmicsLake/man/clear_adapters.html).

## Usage

``` r
registerPhysioAdapters()
```

## Value

Invisibly `TRUE`.
