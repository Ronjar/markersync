#' Sync fulltext markdown for all literature notes
#'
#' Walks every `.md` file in `notes_dir`, extracts the Zotero PDF item ID
#' from the note's `zotero://select/library/items/...` link, locates the
#' PDF in Zotero's storage, and converts it via [pdf_to_md()] if no
#' fulltext file exists yet.
#'
#' Each note's filename (without the `.md` extension) is taken as the
#' citekey, and the resulting fulltext is written as
#' `<fulltext_dir>/<citekey>.md`.
#'
#' @param notes_dir Directory containing literature notes named by citekey.
#' @param fulltext_dir Directory where Marker output should land.
#' @param zotero_storage Zotero local storage root. Defaults to
#'   `~/Zotero/storage`. Override per-machine via the `ZOTERO_STORAGE`
#'   environment variable.
#' @param force If `TRUE`, re-convert even when fulltext already exists.
#' @param ... Additional arguments passed to [pdf_to_md()] (e.g.
#'   `force_ocr`, `marker_url`).
#'
#' @return A list with character vectors for `converted`, `no_pdf_link`,
#'   `pdf_missing`, and `failed` citekeys (invisibly).
#' @export
sync_fulltext <- function(notes_dir      = "literature/notes",
                          fulltext_dir   = "literature/fulltext",
                          zotero_storage = Sys.getenv(
                            "ZOTERO_STORAGE",
                            path.expand("~/Zotero/storage")
                          ),
                          force          = FALSE,
                          ...) {

  if (!dir.exists(notes_dir)) {
    stop("Notes directory not found: ", notes_dir)
  }
  if (!dir.exists(zotero_storage)) {
    warning("Zotero storage not found at: ", zotero_storage,
            "\nSet ZOTERO_STORAGE env var or pass `zotero_storage`.")
  }

  note_files <- list.files(notes_dir, "\\.md$", full.names = TRUE)
  if (length(note_files) == 0) {
    message("No notes in ", notes_dir)
    return(invisible(list()))
  }

  existing <- tools::file_path_sans_ext(
    list.files(fulltext_dir, "\\.md$", full.names = FALSE)
  )

  results <- list(
    converted   = character(),
    no_pdf_link = character(),
    pdf_missing = character(),
    failed      = character()
  )

  for (note_file in note_files) {
    citekey <- tools::file_path_sans_ext(basename(note_file))

    if (!force && citekey %in% existing) next

    pdf_id <- extract_pdf_id(note_file)
    if (is.null(pdf_id)) {
      message("\u26a0 ", citekey, ": no Zotero PDF link in note")
      results$no_pdf_link <- c(results$no_pdf_link, citekey)
      next
    }

    pdf_path <- find_zotero_pdf(pdf_id, zotero_storage)
    if (is.null(pdf_path)) {
      message("\u26a0 ", citekey, ": PDF not found (Zotero ID ", pdf_id, ")")
      results$pdf_missing <- c(results$pdf_missing, citekey)
      next
    }

    res <- tryCatch(
      pdf_to_md(pdf_path, out_dir = fulltext_dir, cite_key = citekey, ...),
      error = function(e) {
        message("\u2717 ", citekey, ": ", conditionMessage(e))
        e
      }
    )

    if (inherits(res, "error")) {
      results$failed <- c(results$failed, citekey)
    } else {
      results$converted <- c(results$converted, citekey)
    }
  }

  message("\n--- Sync summary ---")
  message("Converted:        ", length(results$converted))
  message("No PDF link:      ", length(results$no_pdf_link))
  message("PDF file missing: ", length(results$pdf_missing))
  message("Failed:           ", length(results$failed))

  invisible(results)
}

#' Extract the Zotero PDF item ID from a literature note
#'
#' Scans a note for a `zotero://select/library/items/<ID>` link. Prefers
#' the link on a line marked `**PDF:**`; falls back to the first such
#' link anywhere in the file.
#'
#' @param note_file Path to a Markdown file.
#' @return Item ID string, or `NULL` if none found.
#' @export
extract_pdf_id <- function(note_file) {
  lines <- readLines(note_file, warn = FALSE)

  zotero_pattern <- "zotero://select/library/items/([A-Z0-9]+)"

  # Preferred: a line that mentions PDF *and* contains a zotero link.
  # Match case-insensitively so "PDF", "pdf", "**PDF:**" all work.
  pdf_lines <- grep("pdf", lines, ignore.case = TRUE, value = TRUE)
  for (line in pdf_lines) {
    m <- regmatches(line, regexec(zotero_pattern, line))[[1]]
    if (length(m) >= 2 && nzchar(m[[2]])) return(m[[2]])
  }

  # Fallback: first zotero://select link anywhere in the document
  for (line in lines) {
    m <- regmatches(line, regexec(zotero_pattern, line))[[1]]
    if (length(m) >= 2 && nzchar(m[[2]])) return(m[[2]])
  }

  NULL
}

#' Locate a Zotero attachment PDF on disk
#'
#' @param item_id Zotero attachment item ID (from a `zotero://select` link).
#' @param storage_root Path to `Zotero/storage`.
#' @return Absolute path to the first PDF in `<storage_root>/<item_id>/`,
#'   or `NULL` if the directory or any PDF is missing.
#' @export
find_zotero_pdf <- function(item_id, storage_root) {
  dir <- file.path(storage_root, item_id)
  if (!dir.exists(dir)) return(NULL)
  pdfs <- list.files(dir, "\\.pdf$", full.names = TRUE, ignore.case = TRUE)
  if (length(pdfs) == 0) return(NULL)
  pdfs[[1]]
}

#' Show sync status without converting
#'
#' Quick summary of how many notes have matching fulltext files.
#'
#' @param notes_dir Directory of literature notes.
#' @param fulltext_dir Directory of converted Markdown.
#' @return Invisible list of `notes`, `with_fulltext`, `missing` citekeys.
#' @export
sync_status <- function(notes_dir    = "literature/notes",
                        fulltext_dir = "literature/fulltext") {
  notes <- if (dir.exists(notes_dir))
    tools::file_path_sans_ext(list.files(notes_dir, "\\.md$"))
  else character()

  full <- if (dir.exists(fulltext_dir))
    tools::file_path_sans_ext(list.files(fulltext_dir, "\\.md$"))
  else character()

  with_full <- intersect(notes, full)
  missing   <- setdiff(notes, full)

  message("Notes:         ", length(notes))
  message("With fulltext: ", length(with_full))
  message("Missing:       ", length(missing))

  invisible(list(
    notes         = notes,
    with_fulltext = with_full,
    missing       = missing
  ))
}
