# markersync

R package for syncing Zotero-managed PDFs to Markdown via a self-hosted
[Marker](https://github.com/datalab-to/marker) server.

The typical workflow:

1. You write literature notes in `literature/notes/<citekey>.md`. Each
   note contains a `zotero://select/library/items/<ID>` link to the
   PDF — Zotero plugins like Notero or Better Notes emit these by
   default.
2. You run `sync_fulltext()`. It finds notes that don't yet have a
   fulltext file, looks up each PDF in your local Zotero storage, and
   sends it to your Marker server. The returned Markdown lands in
   `literature/fulltext/<citekey>.md`, with extracted images decoded
   to `literature/fulltext/figures/<citekey>/`.

## Install

```r
# Directly from GitHub:
remotes::install_github("YOUR-USERNAME/markersync")

# Or from a local tarball:
install.packages("markersync_X.Y.Z.tar.gz", repos = NULL, type = "source")
```

Dependencies (`httr2`, `curl`, `base64enc`) install automatically from CRAN.

## Configuration

Add to `~/.Renviron` (one-time, per machine):

```
ZOTERO_STORAGE=/Users/yourname/Zotero/storage
MARKERSYNC_URL=https://your-marker-server.example.com/marker/upload
```

Restart R for changes to take effect. The `MARKERSYNC_URL` must point at
a running Marker API endpoint — see
[datalab-to/marker](https://github.com/datalab-to/marker) for setup.

## Usage

The expected layout:

```
project/
└── literature/
    ├── notes/         # one .md per paper, named by citekey,
    │                  # containing a zotero://select/library/items/ID link
    └── fulltext/      # populated by sync_fulltext()
```

Then:

```r
library(markersync)

sync_status()                   # show what's missing
sync_fulltext()                 # convert anything without fulltext
sync_fulltext(force_ocr = TRUE) # re-convert with forced OCR (scanned PDFs)
sync_fulltext(force = TRUE)     # re-convert everything
```

Convert a single PDF directly without going through the notes flow:

```r
pdf_to_md("some-paper.pdf", cite_key = "smith2024")
pdf_to_md("scanned.pdf",    force_ocr = TRUE)
pdf_to_md("long-paper.pdf", page_range = "0-9")  # first 10 pages
```

## Note format

Each note in `literature/notes/<citekey>.md` should contain a Zotero PDF
link. The package looks for any line containing "pdf" (case-insensitive)
that includes a `zotero://select/library/items/<ID>` URL — for example:

```markdown
- **PDF:** [PDF](zotero://select/library/items/QE88SWIQ)
```

If no such line is found, it falls back to the first
`zotero://select/library/items/<ID>` link anywhere in the file. Most
Zotero note-export plugins (Notero, Better Notes, MD Notes) emit the
standard format above out of the box.

## How PDFs are resolved

Given a Zotero item ID `QE88SWIQ`, the package looks for the PDF at:

```
$ZOTERO_STORAGE/QE88SWIQ/<filename>.pdf
```

The first `.pdf` in that directory is used. This is the default Zotero
storage layout on macOS, Linux, and Windows. If you use Zotero's
"linked attachments" feature with a custom directory, set
`ZOTERO_STORAGE` to point there instead.

## Server-side

This package is a client. You need a running Marker server that exposes
an `/upload` endpoint accepting multipart form-data with a `file` field.
The simplest setup is the Docker image built from
[datalab-to/marker](https://github.com/datalab-to/marker), behind a
reverse proxy with HTTPS.

The server response shape that markersync expects:

```json
{
  "success": true,
  "format": "markdown",
  "output": "# Paper title\n\n...",
  "images": {
    "_page_0_Picture_0.jpeg": "<base64>",
    "...": "..."
  },
  "metadata": { ... }
}
```

## License

MIT
