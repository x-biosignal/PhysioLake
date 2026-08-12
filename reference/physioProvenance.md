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
