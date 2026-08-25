# A cross-platform isolated OmicsLake for tests. Lake$new()'s first argument is a
# project NAME (the lake lives at <ol.root>/<name>), not a filesystem path. Passing
# a tempfile() path as the name works on Unix by accident but breaks on Windows,
# where the drive-letter colon makes file.path(root, name) an invalid path and the
# DuckDB backend cannot open its database. Use a unique name under a valid temp root.
new_test_lake <- function() {
  OmicsLake::Lake$new(basename(tempfile("pl")), root = tempdir())
}
