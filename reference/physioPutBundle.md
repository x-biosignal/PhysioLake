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
