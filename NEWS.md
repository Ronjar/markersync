# markersync 0.2.0

* `status()` renamed to `sync_status()` for namespace clarity.
* `MARKERSYNC_URL` is now required: removed lab-specific default. The
  package errors with a clear message if neither the env var nor the
  `marker_url` argument is set.
* README and package docs updated for public release.

# markersync 0.1.1

* Fixed PCRE compile error in `extract_pdf_id()`: variable-length
  lookbehinds replaced with line-by-line matching using a capture
  group.
* `extract_pdf_id()` now matches case-insensitively, so `pdf:`,
  `**PDF:**`, etc. all work.

# markersync 0.1.0

* Initial release: `pdf_to_md()`, `sync_fulltext()`, `extract_pdf_id()`,
  `find_zotero_pdf()`, `status()`.
