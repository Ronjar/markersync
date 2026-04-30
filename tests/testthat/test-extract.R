test_that("extract_pdf_id finds the preferred PDF link", {
  tmp <- tempfile(fileext = ".md")
  writeLines(c(
    "## Some Paper",
    "- **Zotero item:** [Open item](zotero://select/library/items/AAAAAAAA)",
    "- **PDF:** [PDF](zotero://select/library/items/QE88SWIQ)"
  ), tmp)

  expect_equal(extract_pdf_id(tmp), "QE88SWIQ")
  unlink(tmp)
})

test_that("extract_pdf_id handles a lowercase 'pdf' marker", {
  tmp <- tempfile(fileext = ".md")
  writeLines(c(
    "Item: [Open](zotero://select/library/items/AAAAAAAA)",
    "pdf: [Download](zotero://select/library/items/LOWERCASE)"
  ), tmp)

  expect_equal(extract_pdf_id(tmp), "LOWERCASE")
  unlink(tmp)
})

test_that("extract_pdf_id falls back to any zotero link", {
  tmp <- tempfile(fileext = ".md")
  writeLines(c(
    "Some text",
    "Random link: zotero://select/library/items/FALLBACK"
  ), tmp)

  expect_equal(extract_pdf_id(tmp), "FALLBACK")
  unlink(tmp)
})

test_that("extract_pdf_id returns NULL when no link present", {
  tmp <- tempfile(fileext = ".md")
  writeLines("Just some markdown.", tmp)
  expect_null(extract_pdf_id(tmp))
  unlink(tmp)
})

test_that("find_zotero_pdf returns NULL for missing dir", {
  expect_null(find_zotero_pdf("DOESNOTEXIST", tempdir()))
})

test_that("find_zotero_pdf finds the PDF when present", {
  storage <- tempfile()
  dir.create(file.path(storage, "ABCD1234"), recursive = TRUE)
  pdf <- file.path(storage, "ABCD1234", "paper.pdf")
  file.create(pdf)

  expect_equal(normalizePath(find_zotero_pdf("ABCD1234", storage)),
               normalizePath(pdf))
  unlink(storage, recursive = TRUE)
})

test_that("sync_status reports counts correctly", {
  tmp <- tempfile()
  notes <- file.path(tmp, "notes")
  full  <- file.path(tmp, "fulltext")
  dir.create(notes, recursive = TRUE)
  dir.create(full,  recursive = TRUE)

  file.create(file.path(notes, "a.md"), file.path(notes, "b.md"))
  file.create(file.path(full,  "a.md"))

  res <- suppressMessages(sync_status(notes, full))
  expect_equal(length(res$notes), 2)
  expect_equal(res$with_fulltext, "a")
  expect_equal(res$missing, "b")

  unlink(tmp, recursive = TRUE)
})
